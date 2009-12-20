#
# UserAuthentication provides a method create_session to the included class
# that will build and return a session model.
#
# There are three knobs to tweak to modify behavior per-controller.
# auth_module: #login(self) will be called on this class to get back user || nil
# user_model: the class to use to find the user
# session_model: the returned class
#
# Any user-compatible model will define authentication_scope method.  Other
# plugins may use it to restrict access.  It will return something respoinding
# to .find() like and ActiveRecord model or scope.
#
module UserAuthentication

  private

  def create_session
    auth_module = self.class.send(:auth_module_for_this_controller)
    if auth_module
      auth_module.login(self)
    else
      raise "Unconfigured UserSystem -- needs authentication module"
    end
  end

  def user_scope
    user = self.class.send(:user_model_for_this_controller)
    user.authentication_scope
  end

end
