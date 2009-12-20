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

# UserRedirect handles redirecting users upon login, account creation, and
# other points in the application when performing actions on the user.  It is
# only useful when included in a controller.  It expects redirect_to to be
# a method to be called if a callback redirects (and hide_action to keep
# callbacks from showing up as actions).
#
# It needs to be extensible so other methods can hook into it.  To this end it
# uses ActiveSupport::Callbacks.  To add a new callback use
#   module MyModuleWithMyCallback
#     def my_method user_record
#       # check a condition, maybe redirect
#       # return non-false to pass on to later callbacks
#     end
#   end
#   UserRedirect.on_redirection :my_method
#   UserRedirect.send :include, MyModuleWithMyCallback

# see UserEmailVerificationRedirect for an example
#
module UserRedirect

  private

  @@callback_names = []
  mattr_accessor :callback_names

  @@included_in = []
  mattr_accessor :included_in

  @@inclusive = []
  mattr_accessor :inclusive

  # This way a callback gets added to us (and everything we will be included
  # in later) and to the things we were mixed into before we got the new
  # methods.
  def self.on_redirection symbol
    callback_names << symbol
    included_in.each{|x| x.on_redirection(symbol)}
  end

  # When a class includes this module, we need to remember the class so we can
  # add methods that are added to us later on back into it.
  # Every module we have included, the class including us should include as well
  # so it can have all the methods and any self.included hooks can run.
  def self.included kls

    # remember this in case other callbacks come online later
    included_in  << kls

    # if we already have other modules providing callbacks, mix them in
    inclusive.each{|m| kls.send :include, m}

    # introduce callback mojo
    # the callbacks are built per including controller
    # so one controller may include some others don't
    # but each controller get everything mixed directly into UserRedirect
    kls.send :include, ActiveSupport::Callbacks
    kls.send :define_callbacks, :on_redirection
    kls.send :hide_action, :callback_names, :callback_names=,
                           :included_in, :included_in=,
                           :run_callbacks
    callback_names.each{|x| kls.on_redirection(x)}
  end

  # When we include something, we remember it so we can include it into
  # everything else later on, and we inlcude it in anything we're already in.
  def self.include mod
    super
    included_in.each{|c| c.send(:include, mod)}
    inclusive << mod
  end

  # Walk through all the callbacks that have been registered until
  # one redirects.
  def user_redirect user_record
    self.class.on_redirection_callback_chain.each do |callback|
      rv = callback.call(self, user_record)
      break if performed?
    end
    go_back unless performed?
    go_to_default unless performed?
  end

  # Redirect back to stored location, if any
  def go_back
    if session[:last_params]
      redirect_to session[:last_params]
      session[:last_params] = nil
    end
  end

  # Go to a configurable default, or just root_path
  def go_to_default
    if p = UserSystem.default_path
      v = p.is_a?(Symbol) ? send(p) : p
      redirect_to(v)
    else
      redirect_to root_path
    end
  end

end

##
# A module to check email verification that is mixed into UserRedirect
#
module UserEmailVerificationRedirect
  def verify_email user_record
    if UserSystem.verify_email and !user_record.verified
      redirect_to request_verification_user_path(user_record)
    end
  end
end

UserRedirect.on_redirection :verify_email
UserRedirect.include UserEmailVerificationRedirect
