# Copyright (c) 2008 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#
# A user is the identity of someone who has access to the site.
#
class User < ActiveRecord::Base

  has_many :disabled_periods, :as => :disabled_item
  belongs_to :current_disabled_period,
             :foreign_key => :disabled_period_id,
             :class_name => 'DisabledPeriod'

  before_create :mark_as_verified_if_email_verification_not_required
  before_create :set_security_token_if_verification_needed
  before_save :set_lowercase_login

  validate :presence_of_email_if_required
  validates_presence_of :login, :passphrase
  validates_uniqueness_of :login, :case_sensitive => false
  validates_uniqueness_of :email, :allow_blank => true
  validates_uniqueness_of :security_token, :allow_blank => true
  validates_length_of :passphrase, :minimum => 5
  validate_on_create :passphrase_confirmation_match

  attr_reader :error_message, :passphrase_confirmation

  attr_protected :security_token, :security_token_created_at
  attr_protected :verified, :reset_passphrase, :disabled_from, :disabled_until

  named_scope :verified, {:conditions => {:verified => true}}
  named_scope :unverified, {:conditions => {:verified => false}}
  named_scope :disabled,
              lambda{
                # TODO OPTIMIZE make sure an index is on disabled_item_type
                # and if using mysql do "BINARY 'USER'" to use index
                cond = merge_conditions({
                         'disabled_periods.disabled_item_type' => 'User'
                       })
                now = Time.now
                {
                  :joins => [
                    "LEFT JOIN disabled_periods ON #{cond} " +
                    "AND disabled_periods.disabled_item_id = users.id"
                  ],
                  :conditions => [
                    'disabled_periods.disabled_from <= ? ' +
                    'AND (disabled_periods.disabled_until > ? ' +
                    'OR disabled_periods.disabled_until IS NULL)',
                    now, now
                  ]
                }
              }
  named_scope :active,
              lambda{
                now = Time.now
                cond = merge_conditions(
                         {'disabled_periods.disabled_item_type' => 'User'},
                         [
                           'disabled_periods.disabled_from <= ? ' +
                           'AND (disabled_periods.disabled_until > ? ' +
                           'OR disabled_periods.disabled_until IS NULL)',
                           now, now
                         ]
                       )
                {
                  :joins => [
                    "LEFT JOIN disabled_periods ON #{cond} " +
                    "AND disabled_periods.disabled_item_id = users.id"
                  ],
                  :conditions => {'disabled_periods.id' => nil}
                }
              }
  named_scope :ordered_by_login, {:order => 'login'}

  ##
  #
  # Users can be disabled at points in time.
  # This checks if they are or not.  It defaults to right now, but could
  # check any time, but only one disabled period is stored on the record,
  # so we have no way of checking their historical disabling.
  #
  def disabled? time=Time.now
    return false unless disabled_from
    return true unless disabled_until
    return (disabled_from <= time && disabled_until > time)
  end

  ##
  #
  # Disable this user.  It goes into effect right now.  By default it
  # will diabled them forever, but you can specify and end time.
  # If you specify a time before the current time, it will be set to nil.
  #
  def disable! until_time=nil
    now = Time.now
    until_time and (until_time = nil if until_time < now)
    self.disabled_from = now
    self.disabled_until = until_time
    DisabledPeriod.disable! self, now, until_time
    save!
  end

  ##
  #
  # Login is a protected field.  It should not be reset once it has been
  # committed.  Also, we track lowercase_login to compute uniqueness against
  # other logins, since we want logins to be case insensitive, so set it here
  # as well.  Additionally, configuration may specify that we use an
  # email address as a login, so set the email address off this field
  # if that is the case.
  #
  def login= new_login
    return if UserSystem.email_is_login

    # don't allow it to be re-set
    if new_record? or login.nil? or (dc=new_login.downcase) == login.downcase
      write_attribute(:login, new_login)
    end
  end

  ##
  #
  # Passwords are hased, so compute the hash when assigning it.
  #
  def passphrase= new_passphrase
    write_attribute(:passphrase, pw_hash(new_passphrase))
  end

  ##
  #
  # Email can also act as the login name of the user based on configuration
  #
  # Changing the email when verification is on will mark the record as
  # unverified, and wait for the user to verify the new email address.
  #
  def email= eml
    write_attribute :email, eml
    if UserSystem.email_is_login
      write_attribute :login, eml
    end
    write_attribute :verified, false if UserSystem.verify_email and !new_record?
  end

  ##
  #
  # Passwords are hased, so compute the hash when assigning it.
  #
  def passphrase_confirmation= new_passphrase
    @passphrase_confirmation = pw_hash(new_passphrase)
  end

  ##
  #
  # Login with the given login and passphrase.
  # Will return a user instance or nil.
  #
  def self.login options
    passphrase = options[:passphrase]
    login = options[:login]
    scope = options[:scope] || self

    u = scope.find(:first, :conditions => {:lowercase_login =>login.downcase})
    if (u and (u.passphrase == pw_hash(passphrase)))
      u.update_attribute :last_login, Time.now
      u
    else
      nil
    end
  end

  ##
  #
  # Set a new security token and timeout
  #
  def update_security_token! has_duration=20.minutes
    self.security_token = generate_security_token
    if has_duration
      self.security_token_valid_until = Time.now + has_duration
    end
    save!
  end

  ##
  #
  # Find by security token, if token has not expired
  #
  def self.for_security_token tok
    find(
      :first,
      :conditions => [
        'security_token = ? AND (security_token_valid_until >= ? or security_token_valid_until IS NULL)',
        tok, Time.now
      ]
    )
  end

  ##
  #
  # Mark the record as verified
  #
  def verify!
    update_attribute(:verified, true)
  end

  ##
  #
  # Override the security_token getter, generate one if none exists
  #
  def security_token
    unless read_attribute(:security_token)
      if new_record?
        self.security_token = generate_security_token
      else
        update_attribute(:security_token, generate_security_token)
      end
    end
    read_attribute(:security_token)
  end

  private
  def pw_hash str
    self.class.pw_hash(str)
  end

  def self.pw_hash str
    Digest::MD5.hexdigest(str)
  end

  def passphrase_confirmation_match
    unless @passphrase_confirmation == passphrase
      errors.add(:passphrase, 'does not match confirmation')
    end
  end

  def presence_of_email_if_required
    if UserSystem.verify_email
      errors.add_on_blank :email, "should not be blank"
    end
  end

  def mark_as_verified_if_email_verification_not_required
    unless UserSystem.verify_email
      self.verified = true
    end
  end

  def set_security_token_if_verification_needed
    if UserSystem.verify_email
      self.security_token = generate_security_token
    end
  end

  def generate_security_token
    diff = UserSystem.maximum_security_token_length - \
           UserSystem.minimum_security_token_length
    len = rand(diff) + UserSystem.minimum_security_token_length
    rv = ''
    chrs = UserSystem.security_token_characters
    len.times{ rv << chrs[rand(chrs.length)] }
    rv
  end

  def set_lowercase_login
    self.lowercase_login = self.login.downcase
  end
end
