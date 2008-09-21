require File.join(File.dirname(__FILE__), '..', 'user_system_test_helper')

context 'A class including UserRedirect' do
  setup do
    class M
      include UserRedirect
      def performed? ; @performed ; end
      def redirect_to *opts ; @performed = true ; @redirected_to = opts ; end
      def session ; {} ; end

      def edit_user_path(user_record) ; 'EDIT_USER' ; end
    end

    @kls = M.new

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

        def self.included kls
          kls.send :on_redirection, :new_callback
        end
      end
      UserRedirect.send :include, Ext
    end

    it 'should add new callbacks to old include' do
      assert M.on_redirection_callback_chain.detect{|x| x.method == :new_callback}
    end

    it 'should add all callbacks to new include' do
      class C2
        include UserRedirect
      end
      assert C2.on_redirection_callback_chain.detect{|x| x.method == :new_callback}
    end
  end

end
