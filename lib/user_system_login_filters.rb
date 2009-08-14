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

module UserSystemLoginFilters

  private

  def self.included(kls)
    kls.send :extend, ClassMethods
    kls.send :helper_method, :current_user
  end

  #
  # So any controller can call current_user to get the logged in user
  #
  def current_user
    @usys_logged_in_user ||= lookup_user
  end

  #
  # This is the fallback case.  It can be alias-chained by other plugins.
  #
  def lookup_user
    UserSystem.dont_use_session ? nil : User.find_by_id(session[:user_id])
  end

  #
  # Make sure a user is stored in the session.
  #     before_filter :require_login
  #
  def require_login
    unless current_user
      unless UserSystem.dont_use_session
        puts "STORING LAST PARAMS: #{UserSystem.dont_use_session}"
        session[:last_params] = params
      end
      redirect_to new_session_url
      return
    end

    validate_user(current_user)
  end

  #
  # This method is used internally by only_for_user class method
  #
  def require_user_login *valid_users
    if !current_user or (!valid_users.empty? and !valid_users.include?(current_user))
      # TODO: if current_user, but not valid, use 403, otherwise 401
      unless UserSystem.dont_use_session
        puts "STORING PARAMS(2): #{UserSystem.dont_use_sesion}"
        session[:last_params] = params
        flash[:notice] = 'You need to login to proceed.'
      end
      redirect_to new_session_url
      return
    end

    validate_user(current_user)
  end

  #
  # During login filter checking, stop processing if the user is not verified
  # or is disabled, etc.
  #
  def validate_user current_user
    if current_user.disabled?
      redirect_to inform_disabled_user_path(current_user)
      return false
    end

    if !current_user.verified? and UserSystem.verify_email
      redirect_to request_verification_user_path(current_user)
      return false
    end

    true
  end

  module ClassMethods
    #
    # Mark this controller (or certin actions using :only => ...)
    # as protected and only accessable for certain users.
    #
    def only_for_user *users
      options = users.last.is_a?(Hash) ? users.pop : {}
      _users = users.collect{|x| userify(x) }
      before_filter(options) do |inst|
        inst.send :require_user_login, *_users
      end
    end

    private

    # internal helper
    def to_model(str_or_model, model_class, finder)
      if str_or_model.is_a?(model_class)
        str_or_model
      else
        model_class.send(finder, str_or_model.downcase)
      end
    end

    # internal helper
    def userify(str_or_user)
      to_model(str_or_user, User, :find_by_name)
    end
  end

end
