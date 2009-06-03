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

  filter_parameter_logging :passphrase
  skip_before_filter :require_login
  include UserRedirect

  def create
    if u = perform_user_login
      session[:user_id] = u.id
      user_redirect(u)
    else
      flash.now[:error] = "Unable to login. " +
                      "Ensure your login name and passphrase are correct.  " +
                      "Passphrases are case-sensitive"
      render :action => 'new'
    end
  end

  def destroy
    session[:user_id] = nil
    flash.now[:notice] = "You are now logged out"
    redirect_to :action => 'new'
  end
  alias :end :destroy

  private
  def perform_user_login
    User.login(params[:session].merge(:scope => login_scope))
  end

  def login_scope
    User
  end
end
