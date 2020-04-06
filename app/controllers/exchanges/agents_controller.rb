class Exchanges::AgentsController < ApplicationController
  before_action :check_agent_role
  before_action :check_for_paper_app, only: [:resume_enrollment]
  def home
     @title = current_user.agent_title
     person_id = session[:person_id]
     @person=nil
     @person = Person.find(person_id) if person_id.present?
     if @person && !@person.csr_role && !@person.assister_role
       root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + person_id
       hbx_profile = HbxProfile.find_by_state_abbreviation(aca_state_abbreviation)
       message_params = {
         sender_id: hbx_profile.id,
         parent_message_id: hbx_profile.id,
         from: 'Plan Shopping Web Portal',
         to: "Agent Mailbox",
         subject: "Account link for  #{@person.full_name}. ",
         body: "<a href='" + root+"'>Link to access #{@person.full_name}</a>  <br>",
       }
       create_secure_message message_params, current_user.person, :inbox
     end
     session[:person_id] = nil
     session[:original_application_type] = nil
     render 'home'
  end

  def begin_employee_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_insured_employee_index_path
  end

  def begin_consumer_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_insured_consumer_role_index_path
  end

  def resume_enrollment
    if @person.resident_role && @person.is_resident_role_active? && @person.resident_role.bookmark_url
      redirect_to bookmark_url_path(@person.resident_role.bookmark_url)
    elsif @person.consumer_role && @person.is_consumer_role_active? && @person.consumer_role.bookmark_url
      redirect_to bookmark_url_path(@person.consumer_role.bookmark_url)
    elsif @person.employee_roles.last && @person.employee_roles.last.bookmark_url
      redirect_to bookmark_url_path(@person.employee_roles.last.bookmark_url)
    else
      redirect_to family_account_path
    end
  end

  def inbox
    @inbox_provider = current_user.person
    @profile=@inbox_provider
    @folder = params[:folder] || 'inbox'
    @sent_box = false
  end

  def show
  end

  def check_agent_role
    redirect_to root_path, :flash => { :error => "You must be an Agent:  CSR, CAC, IPA or a Broker" } unless user_permission_satisfied?
    # Do we need to update home_exchanges_agents_path as the last_portal_visited for agents ?
    # What's the use of saving this path as last_portal_visited ?
    # current_user.last_portal_visited = home_exchanges_agents_path
    # current_user.save!
  end

  def check_for_paper_app
    session[:person_id] = params[:person_id]
    session[:original_application_type] = params['original_application_type']
    @person = Person.find(params[:person_id])
    if session[:original_application_type] == "paper"
      @person.set_ridp_for_paper_application(session[:original_application_type])
      redirect_to family_account_path
    end
  end


  private

  def bookmark_url_path(bookmark_url)
    uri = URI.parse(bookmark_url)
    bookmark_path = uri.path
    bookmark_path += "?#{uri.query}" unless uri.query.blank?
    return bookmark_path
  end

  def user_permission_satisfied?
    @roles = []
    ['agent', 'hbx_staff', 'broker', 'broker_agency_staff', 'general_agency_staff'].each do |role|
      @roles << current_user.public_send("has_#{role}_role?")
    end
    @roles.include?(true) ? true : false
  end
end
