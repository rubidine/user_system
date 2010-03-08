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
    render '/sessions/new'
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
      render '/sessions/new'
    end
  end

  def destroy
    session[:session_id] = nil
    session[:user_id] = nil
    render '/sessions/new'
  end
  alias :end :destroy

end
