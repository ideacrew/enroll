class RegistrationsController < Devise::RegistrationsController

  before_action :set_referer, only: [:create, :new]

  def new
    super
  end

  def create
    set_role
    super
    @@referer = ""
  end

  def edit
    super
  end

  def update
    super
  end

  private

  def set_referer
    @@referer ||= request.env["HTTP_REFERER"]
  end

  def set_role
    profile = User::PROFILES
    referer = params["user"]["referer"]
    referer = @@referer.present? ? @@referer : (referer || "")

    params["user"]["roles"] = if referer.include?("employers")
        [profile[:employer_profile]]
      elsif referer.include?("brokers")
        [profile[:broker_profile]]
      else
        [profile[:employee_profile]]
      end
  end

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
    roles, profile = user.roles, User::PROFILES
    if roles.include?(profile[:employer_profile])
      new_employers_employer_path
    elsif roles.include?(profile[:broker_profile])
      new_brokers_broker_path
    elsif roles.include?(profile[:employee_profile])
      new_person_path
    else
      root_path
    end
  end

end