class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    referer = params["user"]["referer"] || ""
    request.env['HTTP_REFERER'] = referer
    params["user"]["role"] = ["employer_profile"]  if referer.include?("employers")
    super
  end

  def edit
    super
  end

  def update
    super
  end

  private

  def sign_up_params
    params.require(:user)
          .permit(
                  :email,
                  {role: []},
                  :password,
                  :password_confirmation
                 )
  end

  def account_update_params
    params.require(:user)
          .permit(
                  :email,
                  {role: []},
                  :password,
                  :password_confirmation,
                  :current_password
                 )
  end

  protected

  def after_sign_up_path_for(user)
    role, profile = user.role, User::PROFILES
    if role.include?(profile[:employer_profile])
      new_employers_employer_path
    elsif role.include?(profile[:broker_profile])
      brokers_root_path
    elsif role.include?(profile[:employee_profile])
      new_person_path
    else
      root_path
    end
  end

end