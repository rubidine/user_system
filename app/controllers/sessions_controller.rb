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

##
#
# == Overview
#
# SessionsController performs authentication and is configurable by
# writing some inheritable attributes or by inheriting from it.
#
# Most of the heavly lifting is done in UserAuthentication, which looks
# at the configuration you specify and calls into the appropriate
# authentication backend.
#
# It is possible to have many subclasses of SessionsController in your
# application, each providing a different mechanism for authentication.
#
# == Example of single authentication endpoint
#
# Example using an initializer to set authentication mechanism, in
# this case using twitter oauth authentication to access the site:
#
# <tt>config/initializers/session_auth.rb</tt>
#
#    SessionsController.write_inheritable_attribute(
#      :auth_module,
#      UserSystem::TwitterOauth::Authentication
#    )
#
# == Adding a second authentication endpoint
#
# Example using a subclass to provide an authentication mechanism, in this
# case using a single sign on server:
#
# <tt>app/controllers/sso_sessions_controller.rb</tt>
#
#   class SsoSessionsController < SessionsController
#     write_inheritable_attribute(:auth_module, Sso::UserSystemAuthentication)
#   end
#
# == Example of directing different controllers to different endpoints
#
# Example telling InternalDataController to use SsoSessionsController, and
# MemberDataController will still use SessionsController.
#
#   class InternalDataController < ApplicationController
#     write_inheritable_attribute(
#       :login_url_helper,
#       :new_sso_sessions_path
#     )
#     write_inheritable_attribute(
#       :login_post_url_helper,
#       :sso_sessions_path
#     )
#   end
#
# == Creating an auth module
#
# Auth modules that SessionsController use for authentication should provide
# a self.login(this_controller) method.  There are a number of methods in
# the calling controller that it can make use of:
#
# * this_controller.params
#
# From UserAuthentication
# * this_controller.send(:user_scope)
#
# From UserSystemLoginFilters
# * this_controller.send(:session_model_for_this_controller)
# * this_controller.send(:user_model_for_this_controller)
#
# == Authenticating from a different model
#
#   class PhysicianDocumentsController < ApplicationController
#     write_inheritable_attribute(
#       :login_url_helper,
#       :new_physician_sessions_path
#     )
#     write_inheritable_attribute(
#       :login_post_url_helper,
#       :physician_sessions_path
#     )
#     write_inheritable_attribute(
#       :user_model,
#       :physician
#     )
#   end
#
#   class PhysicianSessionsController < SessionsController
#     write_inheritable_attribute(
#       :user_model,
#       :physician
#     )
#   end
#
class SessionsController < ApplicationController

  skip_before_filter :require_login

  # DEFAULT CONFIGURATION
  #   self.auth_module = PasswordAuthentication
  #   self.session_model = Session
  #   self.user_model = User
  #   self.login_url = nil
  #   self.login_url_helper = :sessions_url
  include UserAuthentication
  include UserRedirect

  def new
    render :template => '/sessions/new'
  end

  def create
    if s = create_session
      session[:session_id] = s.id
      session[:user_id] = s.user_id
      user_redirect(s.user)
    else
      flash.now[:error] = "Unable to login. " +
                      "Ensure your login name and passphrase are correct.  " +
                      "Passphrases are case-sensitive"
      render :template => '/sessions/new'
    end
  end

  def destroy
    session[:session_id] = nil
    session[:user_id] = nil
    render :template => '/sessions/new'
  end
  alias :end :destroy

end
