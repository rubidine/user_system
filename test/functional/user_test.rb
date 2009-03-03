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

context 'Users Controller' do
  setup do
    @controller = UsersController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    @user = create_user(:verified => true)
  end

  it 'should show the form with "new" action' do
    get 'new'
    assert_response 200
  end

  it 'should send password recovery via email' do
    UserMessenger.expects(:deliver_recovery)
    post 'send_recovery', {:user => {:email => @user.email} }
    assert_response 200
  end

  it 'should allow password recovery within a limited time range' do
    UsersController.any_instance.expects(:user_redirect)
    @user.update_security_token!
    get 'perform_recovery', :id => @user.security_token
  end

  it 'should not allow password recovery if request for recovery long ago' do
    @user.update_security_token! -1.days
    get 'perform_recovery', :id => @user.security_token
    assert_redirected_to recover_users_url, flash.inspect
  end

  context 'With email verification turned on' do
    setup do
      UserSystem.verify_email = true
      @user.update_attribute :verified, false
    end

    it 'should verify the account with "verify" action' do
      get 'verify', {:id => @user.security_token}
      @user.reload
      assert @user.verified?
    end
  end

  context 'With public account creation' do
    setup do
      UserSystem.public_account_creation = true
    end

    it 'should allow creation if public account creation is turned on' do
      @user.destroy
      post 'create', :user => atr = FixtureReplacementController::AttributeCollection.find_by_fixture_name(:user).hash
      atr.symbolize_keys!
      assert User.login(:login => atr[:login], :passphrase => atr[:passphrase])
    end

  end

  context 'Without public account creation' do
    setup do
      UserSystem.public_account_creation = false
    end

    it 'should not allow user creation' do
      @user.destroy
      post 'create', :user => atr = FixtureReplacementController::AttributeCollection.find_by_fixture_name(:user).hash
      assert_response 404
    end

  end

end

