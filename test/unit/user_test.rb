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

context 'User' do
  setup do
    @user = create_user
  end

  it 'can be disabled' do
    assert User.active.find(@user.id)
    @user.disable!

    assert @user.disabled?
    @user.reload
    assert @user.disabled?
    assert User.disabled.find(@user.id)
  end

  it 'requires passphrase_confirmation to create account' do
    atr = FixtureReplacementController::AttributeCollection.find_by_fixture_name(:user).hash
    atr.delete(:passphrase_confirmation)
    atr[:login] = 'chester2'
    u = User.new(atr)
    u.valid?
    assert u.errors.on(:passphrase)
  end

  it 'can change login case' do
    @user.login = 'ChEsTeR'
    assert_equal 'ChEsTeR', @user.login
    @user.save && @user.reload
    assert_equal 'ChEsTeR', @user.login
  end

  it 'cannot change login, except for case' do
    @user.login = 'totally_new_login'
    assert_equal 'chester', @user.login
  end

  it 'will not be valid if another user has the same login (case insensitive)' do
    u = new_user(:email => 'email@another.com', :login => 'cHESTER')
    u.valid?
    assert u.errors.on(:login)
  end

  it 'should login regardless of login case given' do
    assert User.login('CHESTer', 'test-test')
  end

  context 'With configuration email_is_login' do
    setup do
      UserSystem.email_is_login = true
    end

    it 'should not create account without giving an email' do
      user = new_user(:email => nil)
      user.valid?
      assert (user.errors.on(:email) || user.errors.on(:login))
    end

    it 'should login with an email' do
      assert User.login('chester@tatft.com', 'test-test')
    end
  end

  context 'Without configuration email_is_login' do
    setup do
      User.delete_all
      UserSystem.email_is_login = false
    end

    it 'should perform login without giving email adress' do
      create_user
      assert User.login('chester', 'test-test')
    end

    it 'cannot create an account without giving a login' do
      user = new_user(:login => nil)
      user.valid?
      assert user.errors.on(:login)
    end

    context 'With configuration verify email' do
      setup do
        UserSystem.verify_email = true
      end

      it 'cannot create an account without giving an email' do
        user = new_user(:email => nil)
        user.valid?
        assert user.errors.on(:email)
      end

    end

    context 'Without configuration verify email' do
      setup do
        User.delete_all
        UserSystem.verify_email = false
      end

      it 'can create an account without giving an email' do
        user = new_user(:email => nil)
        assert user.valid?
      end

    end
  end

  context 'With configuration verify_email' do
    setup do
      UserSystem.verify_email = true
    end

    it 'should unverify email when email changes' do
      assert @user.verified?
      @user.email = 'another@email.com'
      assert !@user.verified?
    end
  end

end

