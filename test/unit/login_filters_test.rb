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

context 'The Login Filter' do
  setup do
    @kls = Object.new
    class << @kls ; include UserSystemLoginFilters ; end
    @user = create_user
    @kls.stubs(:session).returns({:user_id => @user.id})
  end

  it 'should return the current user from the session' do
    assert_equal @user, @kls.send(:current_user)
  end

  it 'should have a filter to require login' do
    # nasty, but we're not in a real controller
    @kls.stubs(:session).returns({})
    @kls.stubs(:params).returns({})
    @kls.stubs(:new_session_url).returns('NEW_SESSION_URL')

    @kls.expects(:redirect_to).with('NEW_SESSION_URL')
    @kls.send(:require_login)
  end

  it 'should stop processing if user is disabled' do
    @kls.stubs(:session).returns({:user_id => @user.id})
    @kls.stubs(:inform_disabled_user_path).returns('EXPECTED_PATH')

    @user.disable!
    @kls.expects(:redirect_to).with('EXPECTED_PATH')
    @kls.send(:require_login)
  end

  context 'When email validation is turned on' do
    setup do
      UserSystem.verify_email = true
    end

    it 'should stop processing if user is not verified' do
      @kls.stubs(:session).returns({:user_id => @user.id})
      @kls.stubs(:request_verification_user_path).returns('PAFF')

      @user.update_attribute :verified, false
      @kls.expects(:redirect_to).with('PAFF')
      @kls.send(:require_login)
    end

  end

end

context 'A class incliding the login filters' do
  setup do
    class Kls ; include UserSystemLoginFilters ; end
    @kls = Kls
    @user = create_user
  end

  it 'can request only certain users to have access to controller' do
    @kls.expects(:before_filter)
    @kls.send(:only_for_user, @user)
  end

end

