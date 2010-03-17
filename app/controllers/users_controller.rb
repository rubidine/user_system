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

#
# Create user accounts
#
class UsersController < ApplicationController

  skip_before_filter :require_login
  include UserRedirect

  before_filter :account_creation_should_be_enabled,
                :only => [ :new, :create ]

  before_filter :security_token_is_not_nil,
                :only => [ :verify, :perform_recovery ]

  #
  # show the form to create a new user
  #
  def new
    @user = User.new

    respond_to :html
  end

  #
  # Create a user record
  #
  def create
    u = User.create(params[:user])

    if u.new_record?
      respond_to do |format|
        format.html do
          flash[:notice] = 'Unable to create user'
          @user = u
          render :action => 'new'
        end
      end
      return
    end

    # send verification email
    if UserSystem.verify_email
      UserMessenger.deliver_verification(u)
    end

    respond_to do |format|
      format.html do
        user_redirect(u)
      end
    end
  end

  #
  # A link to this action is delivered in an email upon signup.
  # By visiting it, the account becomes active.
  #
  def verify
    user = User.find_by_security_token(params[:id])
    unless user
      respond_to do |format|
        format.html do
          flash.now[:notice] = "Invalid verification code"
        end
      end
      return
    end
    user.update_attribute :verified, true

    respond_to do |format|
      format.html do
        user_redirect(user)
      end
    end

  end

  #
  # Ask the user to verify their email address.
  # TODO make user verification is turned on
  # TODO make sure they are not already verified
  #
  def request_verification
    if params[:send_email]
      @user = User.find_by_email(params[:verification][:email])
      if @user
        UserMessenger.deliver_verification @user
      end
    end

    respond_to :html
  end

  #
  # User can provide theie email address to have their password reset and
  # send to them.
  #
  def send_recovery
    @user = User.find_by_email(params[:user][:email])
    unless @user
      respond_to do |format|
        format.html do
          flash[:error] = "Unable to find email address #{@user.email}"
          render :action => 'recover'
        end
      end
      return
    end
    @user.update_security_token! 20.minutes
#    @user.update_attribute :reset_passphrase, true
    UserMessenger.deliver_recovery(@user)

    respond_to :html
  end

  #
  # User has ben sent an email because the forgot their password and the
  # were sent back here.  Give them their account.
  #
  def perform_recovery
    user = User.for_security_token(params[:id])

    respond_to do |format|

      # html #
      format.html do
        if user
          user_redirect(user)
          session[:user_id] = user.id
        else
          flash[:notice] = 'Invalid or expired token'
          redirect_to recover_users_path
        end
      end

      # other formats #
    end
  end

  private

  def account_creation_should_be_enabled
    unless UserSystem.public_account_creation
      render :text => 'Public account creation is disbaled', :status => 404
    end
  end

  def security_token_is_not_nil
    if params[:id].nil? or params[:id].empty?
      raise ActiveRecord::RecordNotFound      
    end
  end
end
