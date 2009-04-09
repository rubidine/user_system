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

module UserSystem

  mattr_accessor :public_account_creation
  self.public_account_creation = true

  mattr_accessor :email_is_login
  self.email_is_login = false

  mattr_accessor :verify_email
  self.verify_email = false

  mattr_accessor :user_messenger_from
  self.user_messenger_from = "nobody@localhost"

  mattr_accessor :site_name
  self.site_name = "My Rails Site"

  mattr_accessor :root_url
  self.root_url = "localhost"

  mattr_accessor :security_token_characters
  self.security_token_characters = ('A'..'Z').to_a +
                                   ('a'..'z').to_a +
                                   ('0'..'9').to_a +
                                   ['-', '_', '!', '~']

  mattr_accessor :minimum_security_token_length
  self.minimum_security_token_length = 30

  mattr_accessor :maximum_security_token_length
  self.maximum_security_token_length = 50

=begin
  attr_accessor :invite_only
  self.invite_only = false

  attr_accessor :administrators_group
  self.administrators_group = "Administrators"

  attr_accessor :default_new_user_groups
  self.default_new_user_groups = ["Users"]

  attr_accessor :public_group_creation
  self.public_group_creation = false

  attr_accessor :group_creation_moderated
  self.group_creation_moderated = false
=end

end
