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
# other points in the application when performing actions on the user.
#
# It needs to be extensible so other methods can hook into it.  To this end it
# uses ActiveSupport::Callbacks.  To add a new callback use
#   UserRedirect.on_redirection :my_method
#   UserRedirect.send :include, MyModuleWithMyCallback
module UserRedirect

  private

  @@callback_names = [:verify_email, :inform_disabled, :reset_passphrase]
  mattr_accessor :callback_names

  @@included_in = []
  mattr_accessor :included_in

  @@inclusive = []
  mattr_accessor :inclusive

  # remember the callback for when we are included in something later on
  # add the callback to everything we are already included in
  def self.on_redirection symbol
    callback_names << symbol
    included_in.each{|x| x.on_redirection(symbol)}
  end

  # add the callbacks into the class
  def self.included kls

    # remember this in case other callbacks come online later
    included_in  << kls

    # if we already have other modules providing callbacks, mix them in
    inclusive.each{|m| kls.send :include, m}

    # introduce callback mojo
    kls.send :include, ActiveSupport::Callbacks
    kls.send :define_callbacks, :on_redirection
    kls.send :hide_action, :callback_names, :callback_names=,
                           :included_in, :included_in=,
                           :run_callbacks

    # include all the callbacks that are already defined
    callback_names.each{|x| kls.on_redirection(x)}
  end

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
    default unless performed?
  end

  def verify_email user_record
    if UserSystem.verify_email and !user_record.verified
      redirect_to request_verification_user_path(user_record)
    end
  end

  def inform_disabled user_record
    if user_record.disabled?
      redirect_to inform_disabled_user_path(user_record)
    end
  end

  def reset_passphrase user_record
    if user_record.reset_passphrase?
      redirect_to edit_user_path(user_record)
    end
  end

  def go_back
    if session[:last_params]
      redirect_to session[:last_params]
    end
  end

  def default
    redirect_to '/'
  end

end
