# frozen_string_literal: true

module Users
  # class for Keycloak account actions
  class AccountsController < ApplicationController
    # GET reset_password
    def forgot_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      @username = params.require(:username)
    rescue Pundit::NotAuthorizedError
      flash[:alert] = "You are not authorized for this action."
      render inline: "location.reload();"
    end

    # PUT confirm_forgot_password
    def confirm_forgot_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      @username = params.require(:username)

      result = Operations::Accounts::ForgotPassword.new.call(username: @username)

      if result.success?
        redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Reset password instruction sent to user email."
      else
        redirect_to user_account_index_exchanges_hbx_profiles_url, error: "Error resetting password."
      end
    rescue Pundit::NotAuthorizedError
      redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
    end

    # GET reset_password
    def reset_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
    end

    def confirm_reset_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      new_password = params.require(:new_password)

      @result = Operations::Accounts::ResetPassword.new.call(
        account: {
          id: @account_id,
          credentials: [{
            type: 'password',
            temporary: true,
            value: new_password
          }]
        }
      )

      if @result.success?
        flash[:notice] = "Password is reset."
      else
        error = @result.failure
        flash[:error] = (error[:error_description] || "Error changing password: #{error&.to_s}")
      end

      render 'password_reset_result'
    rescue Pundit::NotAuthorizedError
      redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
    end

    # GET lockable
    def lockable
      authorize User, :lockable?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      @enabled = params.require(:enabled) == 'true'
    rescue Pundit::NotAuthorizedError
      redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
    end

    # GET confirm_lock
    def confirm_lock
      authorize User, :lockable?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      @enabled = params.require(:enabled) == 'true'

      result = if @enabled
                 Operations::Accounts::Disable.new.call(id: @account_id)
               else
                 Operations::Accounts::Enable.new.call(id: @account_id)
               end

      if result.success?
        flash[:notice] = "Successfully #{@enabled ? 'locked' : 'unlocked'} account."
      else
        flash[:error] = "Error #{@enabled ? 'locking' : 'unlocking'} account."
      end
    rescue Pundit::NotAuthorizedError
      flash[:alert] = "You are not authorized for this action."
      render inline: "location.reload();"
    end

    def change_username_and_email
      authorize User, :change_username_and_email?
      @user_id = params[:user_id]
      @user = User.find(@user_id)
      @account_id = params.require(:account_id)
      @username = params.require(:username)
      @email = params.require(:email)
    rescue Pundit::NotAuthorizedError
      flash[:alert] = "You are not authorized for this action."
      render inline: "location.reload();"
    end

    # rubocop:disable Metrics/AbcSize
    def confirm_change_username_and_email
      authorize User, :change_username_and_email?
      @user_id = params[:user_id]
      @user = User.find(@user_id)
      @account_id = params.require(:account_id)

      attributes = {id: @account_id}
      attributes.merge!(username: params[:new_username].strip) unless params[:current_username] == params[:new_username].strip
      attributes.merge!(email: params[:new_email].strip) unless params[:current_email] == params[:new_email].strip

      result = Operations::Accounts::Update.new.call(account: attributes)

      if result.success?
        @account = Operations::Accounts::Find.new.call(scope_name: :by_username, criterion: params[:new_username].strip).value_or([])[0]
        permission = Permission.find_by(id: params.require(:permission_id))
        @user.person.hbx_staff_role.permission_id = permission.id if permission
        @user.save
      else
        @username_taken = Operations::Accounts::Find.new.call(scope_name: :by_username, criterion: params[:new_username].strip).value_or([])[0] if attributes.key?(:username)
        @email_taken = Operations::Accounts::Find.new.call(scope_name: :by_email, criterion: params[:new_email].strip).value_or([])[0] if attributes.key?(:email)
      end

      respond_to do |format|
        format.js { render "username_email_result"}
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end