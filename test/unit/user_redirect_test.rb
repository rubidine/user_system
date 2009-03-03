require File.join(File.dirname(__FILE__), '..', 'user_system_test_helper')

context 'A class including UserRedirect' do
  setup do
    class M < ActionController::Base
      include UserRedirect
    end

    @kls = M.new
    @kls.session = {}
    @kls.request = ActionController::TestRequest.new
    @kls.response = ActionController::TestResponse.new

    @user = create_user
    @user.verified = true
    @user.reset_passphrase = false
  end

  it 'should not have an empty callback chain' do
    assert !M.on_redirection_callback_chain.empty?
  end

  it 'should walk through callbacks when redirecting' do
    M.on_redirection_callback_chain.each{|c| @kls.expects(c.method) }
    @kls.send(:user_redirect, @user)
  end

  it 'should not call callbacks after one redirects' do
    @user.verified = false
    @kls.expects(:inform_disabled).never
  end

  context 'that has more callbacks added after included once' do
    setup do
      module Ext
        def new_callback
          # no op
        end
      end
      UserRedirect.send :include, Ext
      UserRedirect.send :on_redirection, :new_callback
    end

    it 'should add new callbacks to old include' do
      assert M.on_redirection_callback_chain.detect{|x| x.method == :new_callback}
    end

    it 'should add all callbacks to new include' do
      class C2 < ActionController::Base
        include UserRedirect
      end
      assert C2.on_redirection_callback_chain.detect{|x| x.method == :new_callback}
    end
  end

end
