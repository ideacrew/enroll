class Users::PasswordsController < Devise::PasswordsController
  before_filter :confirm_identity, only: [:create]
  def create
    super
  end

  private

  def user
    @user ||= User.find_by(email: params[:user][:email])
  end

  def confirm_identity
    unless user.identity_confirmed_token == params[:user][:identity_confirmed_token]
      flash[:error] = "Something went wrong, please try again"
      redirect_to new_user_password_path
      return false
    end
  end
end

  protected

  def after_resetting_password_path_for(resource_name)
    root_url
  end
end
