class SessionsController < Devise::SessionsController

  # After successful login, redirect to this page
  def after_sign_in_path_for(resource)
    url, profile = root_path, User::PROFILES
    session[:user_role] = if request.env["HTTP_REFERER"].include?("employers")
      profile[:employer_profile]
    elsif request.referer.include?("brokers")
      profile[:broker_profile]
    else
      profile[:employee_profile]
    end
    resource.update_attribute(:role, resource.role.push(session[:user_role])) if !resource.role.include?(session[:user_role])
    if session[:user_role] == profile[:employer_profile]
      url = current_user.person.present? ? employers_root_path : new_employers_employer_path
    end
    if session[:user_role] == profile[:broker_profile]
      url = current_user.person.present? ? brokers_path : new_brokers_broker_path
    end
    if session[:user_role] == profile[:employee_profile]
      url = current_user.person.present? ? person_path : new_person_path
    end
    url
  end

end