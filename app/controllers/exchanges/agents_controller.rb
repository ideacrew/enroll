class Exchanges::AgentsController < ApplicationController

  def home
     
     @cac = current_user.person.csr_role.try(:cac)
     person_id = session[:person_id]
     if person_id && person_id != ''
     	@person = Person.find(person_id)
     else
     	@person=nil
     end
     render 'home'
  end

  def begin_employee_enrollment
  	session[:person] = nil
  	session[:original_application_type] = params['original_application_type']
	  redirect_to search_insured_employee_index_path
  end

  def begin_consumer_enrollment
    session[:person] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_insured_consumer_role_index_path
  end

  def resume_enrollment
    session[:person_id] = params[:person_id]
    session[:original_application_type] = params['original_application_type']
    redirect_to family_account_path
  end

  def send_enrollment_confirmation
    begin
      person = Person.find(session[:person_id])
    rescue
      person =nil
      @result = 'You are no longer connected to the enrollee account.'
    end

    if person
      first_name = person.first_name
      hbx_id = person.hbx_id
      email = person.emails.first.address
      begin
        mail = UserMailer.generic_consumer_welcome(first_name, hbx_id, email).deliver_now
        @result = 'Email has been sent.   Your session is no longer connected to enrollee'
        puts mail if Rails.env.development?
        session[:person_id] = nil
      rescue
        @result = 'Email send did not occur'
      end
    end
    render layout: false
  end

  def inbox
    @inbox_provider = current_user.person
    @profile=@inbox_provider
    @folder = params[:folder] || 'inbox'
    @sent_box = false  
  end

  def show
  end

end




