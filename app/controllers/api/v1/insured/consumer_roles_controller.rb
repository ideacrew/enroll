class Api::V1::Insured::ConsumerRolesController < ApiController
  include ApplicationHelper
  include VlpDoc
  include ErrorBubble
    
  before_action :check_consumer_role, only: [:search, :match]
  before_action :find_consumer_role, only: [:edit, :update]
  
  def privacy
    set_current_person(required: false)
    @val = params[:aqhp] || params[:uqhp]
    @key = params.key(@val)
    if @person.try(:resident_role?)
      bookmark_url = @person.resident_role.bookmark_url.to_s.present? ? @person.resident_role.bookmark_url.to_s : nil
      #redirect_to bookmark_url || family_account_path
    elsif @person.try(:consumer_role?)
      bookmark_url = @person.consumer_role.bookmark_url.to_s.present? ? @person.consumer_role.bookmark_url.to_s + "?#{@key.to_s}=#{@val.to_s}" : nil
      #redirect_to bookmark_url || family_account_path
    end
  end
  
  def search
    @no_previous_button = true
    @no_save_button = true

    if params.permit(:build_consumer_role)[:build_consumer_role].present? && session[:person_id]
      person = Person.find(session[:person_id])

      @person_params = person.attributes.extract!("first_name", "middle_name", "last_name", "gender")
      @person_params[:ssn] = Person.decrypt_ssn(person.encrypted_ssn)
      @person_params[:dob] = person.dob.strftime("%Y-%m-%d")

      @person = Forms::ConsumerCandidate.new(@person_params)
    else
      @person = Forms::ConsumerCandidate.new
    end
  end
  
  def build
    set_current_person(required: false)
    build_person_params
    #render 'match'
  end
  
  def create
    begin
      @consumer_role = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, actual_user)
      if @consumer_role.present?
        @person = @consumer_role.person
      else
        # not logging error because error was logged in construct_consumer_role
      end
    rescue Exception => e
      #flash[:error] = set_error_message(e.message)
      #redirect_to search_insured_consumer_role_index_path
      return
    end
    @person.primary_family.create_dep_consumer_role if @person
    is_assisted = session["individual_assistance_path"]
    role_for_user = (is_assisted) ? "assisted_individual" : "individual"
    create_sso_account(current_user, @person, 15, role_for_user) do
      #respond_to do |format|
        #format.html {
          if is_assisted
            @person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{@person.id}") if @person.primary_family
            #redirect_to navigate_to_assistance_saml_index_path
          else
            #redirect_to :action => "edit", :id => @consumer_role.id
          end
          #}
        #end
    end
  end
  
  def edit
    authorize @consumer_role, :edit?
    set_consumer_bookmark_url
    @consumer_role.build_nested_models_for_person
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@consumer_role)
  end
  
  private
  
  def find_consumer_role
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
  end


  def check_consumer_role
    set_current_person(required: false)
    # need this check for cover all
    if @person.try(:has_active_resident_role?)
      #redirect_to @person.resident_role.bookmark_url || family_account_path
    elsif @person.try(:has_active_consumer_role?)
      #redirect_to @person.consumer_role.bookmark_url || family_account_path
    else
      current_user.last_portal_visited = search_insured_consumer_role_index_path
      current_user.save!
    end
  end
  
  def build_person_params
    @person_params = {:ssn =>  Person.decrypt_ssn(@person.encrypted_ssn)}

    %w(first_name middle_name last_name gender).each do |field|
      @person_params[field] = @person.attributes[field]
    end

    @person_params[:dob] = @person.dob.strftime("%Y-%m-%d")
    @person_params.merge!({user_id: current_user.id})
  end
  
end