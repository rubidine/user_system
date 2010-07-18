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
# It is not an authentication mechanism.
#
class User < ActiveRecord::Base

  has_many :sessions

  before_create :mark_as_verified_if_email_verification_not_required
  before_create :set_security_token_if_needed
  before_create :set_default_nickname
  before_save :set_lowercase_login

  validate :presence_of_email_if_required_or_explicitly_validated
  validates_presence_of :login
  validates_uniqueness_of :login,
                          :case_sensitive => false,
                          :identifier => 'unique_login'
  validates_uniqueness_of :email,
                          :allow_blank => true,
                          :identifier => 'unique_email'
  validates_uniqueness_of :security_token,
                          :allow_blank => true,
                          :identifier => 'unique_security_token'


  attr_reader :error_message

  attr_protected :security_token, :security_token_created_at
  attr_protected :verified, :disabled_from, :disabled_until

  named_scope :verified, {:conditions => {:verified => true}}
  named_scope :unverified,
              {:conditions => ['verified IS NULL OR verified = ?', false]}
  named_scope :ordered_by_login, {:order => 'login'}
  named_scope :for_login, proc{|l|
    {:conditions => {:lowercase_login => l.downcase}}
  }
  named_scope :for_security_token, proc{|tok|
    {:conditions => [
      'security_token = ? AND ' +
      '(security_token_valid_until >= ? OR security_token_valid_until IS NULL)',
      tok, Time.now
    ]}
  }

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
    if new_record? or login.blank? or new_login.downcase == login.downcase
      write_attribute(:login, new_login)
    end
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
  # Mark the login time and do some other housekeeping.
  # This should be called by each authentication module.
  #
  def logged_in auth_module
    update_attributes(
      :last_login => Time.now,
      :previous_login => last_login
    )
    sessions.clear
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
      # make sure to save it immedietely if we need to
      if new_record?
        self.security_token = generate_security_token
      else
        update_attribute(:security_token, generate_security_token)
      end
    end
    read_attribute(:security_token)
  end

  # This method is used by authentication modules.
  # Make sure the user is validated.
  # This can be chained around by other plugins.
  def self.authentication_scope
    self.verified
  end

  private

  def presence_of_email_if_required_or_explicitly_validated
    if UserSystem.verify_email or UserSystem.require_email
      errors.add_on_blank :email, "should not be blank"
    end
  end

  def mark_as_verified_if_email_verification_not_required
    unless UserSystem.verify_email
      self.verified = true
    end
  end

  def set_security_token_if_needed
    if UserSystem.verify_email or UserSystem.always_generate_security_token
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

  def set_default_nickname
    self.nickname ||= login
  end

end
