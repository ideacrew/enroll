# frozen_string_literal: true

module Users
  # class for Keycloak account actions
  class AccountsController < ApplicationController
    # GET reset_password
    def reset_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      @username = params.require(:username)
    rescue Pundit::NotAuthorizedError
      flash[:alert] = "You are not authorized for this action."
      render inline: "location.reload();"
    end

    # PUT confirm_reset_password
    def confirm_reset_password
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


    # GET change_password
    def change_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
    end

    def confirm_change_password
      authorize User, :reset_password?
      @user_id = params.require(:user_id)
      @account_id = params.require(:account_id)
      new_password = parmas.require(:new_password)

      result = Operations::Accounts::ResetPassword.new.call(
        account: {
          id: @account_id,
          credentials: {
            type: 'password',
            temporary: false,
            value: new_password
          }
        }
      )

      if result.success?
        redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Reset password instruction sent to user email."
      else
        redirect_to user_account_index_exchanges_hbx_profiles_url, error: "Error resetting password."
      end
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
    rescue Pundit::NotAuthorizedError
      flash[:alert] = "You are not authorized for this action."
      render inline: "location.reload();"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def confirm_change_username_and_email
      authorize User, :change_username_and_email?
      @user_id = params[:user_id]
      @user = User.find(@user_id)
      @account_id = params.require(:account_id)

      @element_to_replace_id = params[:family_actions_id]
      @email_taken = User.where(:email => params[:new_email].strip, :id.ne => @user_id).first if params[:new_email]
      @username_taken = User.where(:oim_id => params[:new_oim_id].strip, :id.ne => @user_id).first if params[:new_oim_id]
      if @email_taken.present? || @username_taken.present?
        @matches = true
      else
        username = params[:new_oim_id] if params[:new_oim_id] != params[:current_oim_id]
        email = params[:new_email] if params[:new_email] && (params[:new_email] != params[:current_email])

        result = Operations::Accounts::Update.new.call(account: {username: username, email: email})
        if result.success?
          begin
            @user.oim_id = username
            @user.email = email
            @user.modifier = current_user
            @user.save!
          rescue StandardError
            @errors = @user.errors.messages
          end
        else
          flash[:error] = "Error updating account."
        end
      end

      respond_to do |format|
        format.js { render "change_username_and_email"} if @errors
        format.js { render "username_email_result"}
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  end
end