class UsersController < ApplicationController
  before_filter :confirm_existing_password, only: [:change_password]
  before_filter :set_user, except: [:confirm_lock, :change_username, :change_email]

  def confirm_lock
    params.permit!
    authorize User, :lockable?
    @user_id  = params[:user_action_id]
  end

  def lockable
    authorize User, :lockable?
    @user.lock!
    redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "User #{user.email} is successfully #{user.lockable_notice}."
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def reset_password
    authorize User, :reset_password?
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def confirm_reset_password
    authorize User, :reset_password?
    @error = nil
    validate_email if params[:user].present?
    if @error.nil?
      User.send_reset_password_instructions(email: @user.email)
      redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Reset password instruction sent to user email."
    else
      render file: 'users/reset_password.js.erb'
    end
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def change_password
    @user.password = params[:user][:new_password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save!
      flash[:success] = "Password successfully changed"
    else
      flash[:error] = "We encountered a problem trying to update your password, please try again"
    end
    redirect_to personal_insured_families_path
  end
  
  def change_username
    authorize User, :change_username_and_email?
    @user_id = params[:user_action_id]
  end
  
  def confirm_change_username
    authorize User, :change_username_and_email?
    @user.oim_id = params[:oim_id]
    if @user.save!
      redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Username was changed to #{user.oim_id}."
    else
      redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
    end
  end
  
  def change_email
    authorize User, :change_username_and_email?
    @user_id = params[:user_action_id]
  end
  
  def confirm_change_email
    authorize User, :change_username_and_email?
    @user.email = params[:new_email]
    if @user.save!
      redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Successfully updated the email address"
    else
      flash[:error] = "We encountered a problem trying to update the email address, please try again"
    end
  end

  def edit

  end

  def update
    @user.update_attributes(email_update_params)
  end

  def login_history
    @user_login_history = SessionIdHistory.for_user(user_id: @user.id).order('created_at DESC').page(params[:page]).per(15)
  end
  
  def check_for_existing_username_or_email
    authorize User, :change_username_and_email?
    if params[:email]
      user = User.where(email:params[:email]).first
    elsif params[:oim_id]
      user = User.where(oim_id:params[:oim_id]).first
    end
    if user.present?
      render json: {available:true}
    else
      render json: {available:false}
    end
  end
  
  private
  
  helper_method :user

  def email_update_params
    params.require(:user).permit(:email)
  end
  
  def validate_email
     @error = if params[:user][:email].blank?
               'Please enter a valid email'
             elsif params[:user].present? && !@user.update_attributes(email_update_params)
                @user.errors.full_messages.join.gsub('(optional) ', '')
              end
  end
  
  def user
    @user ||= User.find(params[:id])
  end
  
  def set_user
     @user = User.find(params[:id])
  end
  
  def confirm_existing_password
    unless @user.valid_password? params[:user][:password]
      flash[:error] = "That password does not match the one we have stored"
      redirect_to personal_insured_families_path
      return false
    end
  end
end
