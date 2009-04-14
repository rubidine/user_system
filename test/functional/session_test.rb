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

require File.join(File.dirname(__FILE__), '..', 'user_system_test_helper')

# because this is an implementation detail, dont rely on it.  move it to func
def assert_logged_in specific_user=nil
  if specific_user
    assert_equal specific_user.id, session[:user_id]
  else
    assert session[:user_id]
  end
end

def assert_not_logged_in
  assert_nil session[:user_id]
end

context 'Sessions Controller', ActionController::TestCase do
  setup do
    @controller = SessionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    @user = Factory(:user)
    @user.verify!
  end

  it 'should log a valid user in with create' do
    post 'create', :session => {:login => 'chester', :passphrase => 'test-test'}
    assert_logged_in @user
  end

  it 'should log in a disabled user, but sandbox them' do
    @user.disable!
    post 'create', :session => {:login => 'chester', :passphrase => 'test-test'}
    assert_logged_in
    assert_redirected_to inform_disabled_user_path(@user)
  end

  it 'should not log in a user with improper credentials' do
    post 'create', :session => {:login => 'chester', :passphrase => 'poof'}
    assert_not_logged_in
  end

  it 'should log out user with destroy' do
    @request.session[:user_id] = @user.id
    post 'destroy'
    assert_not_logged_in
  end

  context 'If verify_emails is on', ActionController::TestCase do
    setup do
      UserSystem.verify_email = true
    end

    it 'should not log in an unverified email' do
      @user.update_attribute :verified, false
      post 'create', :session => {:login => 'chester', :passphrase => 'poof'}
      assert_not_logged_in
    end

  end

end

