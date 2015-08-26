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

  def begin_enrollment
  	session[:person] = nil
  	session[:original_application_type] = params['original_application_type']
	  redirect_to search_consumer_employee_index_path
  end

  def send_enrollment_confirmation
  	begin
  	  UserMailer.message_to_enrolled_by_agent(Person.find(session[:person_id]), current_user).deliver_now
  	  @result = 'Email has been sent.   Your session is no longer connected to enrollee'
  	  session[:person_id] = nil
  	rescue
  	  @result = 'Email send did not occur'
  	end
    render layout: false
  end
end




