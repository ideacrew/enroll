class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  private

  def sign_up_params
    params.require(:user)
          .permit(
                  :email,
                  :password,
                  :password_confirmation,
                  :person_attributes => [
                    :first_name,
                    :middle_name,
                    :last_name,
                    :name_sfx,
                    :name_pfx,
                    :dob,
                    :ssn,
                    :gender,
                    :is_active
                  ]
                 )
  end

  def account_update_params
    params.require(:user)
          .permit(
                  :email,
                  :password,
                  :password_confirmation,
                  :current_password
                 )
  end
end