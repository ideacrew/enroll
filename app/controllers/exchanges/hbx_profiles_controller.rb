class Exchanges::HbxProfilesController < ApplicationController

  before_action :check_hbx_staff_role, except: [:welcome, :show, :request_help, :staff_index, :assister_index]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]
  before_action :find_hbx_profile, only: [:employer_index, :family_index, :broker_agency_index, :inbox, :configuration, :show]

  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def employer_index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @employer_profiles = @organizations.map {|o| o.employer_profile}

    respond_to do |format|
      format.html { render "employers/employer_profiles/index" }
      format.js {}
    end
  end

  def staff_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(:$or => [{csr_role: {:$exists => true}}, {assister_role: {:$exists => true}}])
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def assister_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(assister_role: {:$exists =>true})
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def request_help
    role = nil
    if params[:type]
      cac = params[:type] == 'CAC'
      staff = Person.where(:'csr_role.cac' => cac)
      match = staff.where(:$and => [{first_name: params[:firstname].strip},{last_name: params[:lastname].strip}])
      if match.count > 0
        agent = match.first
        role = cac ? 'Certified Applicant Counselor' : 'Customer Service Representative'
      end
    else
      if params[:broker] && params[:broker] != ''
        agent = Person.find(params[:broker])
        role = 'Broker'
      else
        agent = Person.find(params[:assister])
        role = 'In-Person Assister'
      end
    end
    if role
      status_text = 'Message sent to ' + role + ' ' + agent.full_name + ' <br>' 
      if agent.try(:user).try(:email)
        agent_assistance_messages(params,agent,role)
      else
        status_text = "Agent has no email.   Please select another"
      end
    else
      status_text = call_customer_service params[:firstname], params[:lastname]
    end
    render :text => status_text.html_safe, layout: false
  end

  def family_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.page page_no
      @total = Family.count
    else
      total_families = Person.search(@q).map(&:families).flatten.uniq
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      format.html { render "insured/families/index" }
      format.js {}
    end
  end

  def broker_agency_index
    @broker_agency_profiles = BrokerAgencyProfile.all

    respond_to do |format|
      format.html { render "broker" }
      format.js {}
    end
  end

  def issuer_index
    @issuers = CarrierProfile.all


    respond_to do |format|
      format.html { render "issuer_index" }
      format.js {}
    end
  end

  def product_index

    respond_to do |format|
      format.html { render "product_index" }
      format.js {}
    end
  end

  def configuration

    @time_keeper = Forms::TimeKeeper.new

    respond_to do |format|
      format.html { render partial: "configuration_index" }
      format.js {}
    end
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show
    if current_user.has_csr_role?
      redirect_to home_exchanges_agents_path
      return
    else
      check_hbx_staff_role
    end
    @unread_messages = @profile.inbox.unread_messages.try(:count) || 0
  end

  # GET /exchanges/hbx_profiles/new
  def new
    @organization = Organization.new
    @hbx_profile = @organization.build_hbx_profile
  end

  # GET /exchanges/hbx_profiles/1/edit
  def edit
  end

  # GET /exchanges/hbx_profiles/1/inbox
  def inbox
    @inbox_provider = current_user.person.hbx_staff_role.hbx_profile
    @folder = params[:folder] || 'inbox'
    @sent_box = true
  end

  # POST /exchanges/hbx_profiles
  # POST /exchanges/hbx_profiles.json
  def create
    @organization = Organization.new(organization_params)
    @hbx_profile = @organization.build_hbx_profile(hbx_profile_params.except(:organization))

    respond_to do |format|
      if @hbx_profile.save
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully created.' }
        format.json { render :show, status: :created, location: @hbx_profile }
      else
        format.html { render :new }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exchanges/hbx_profiles/1
  # PATCH/PUT /exchanges/hbx_profiles/1.json
  def update
    respond_to do |format|
      if @hbx_profile.update(hbx_profile_params)
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @hbx_profile }
      else
        format.html { render :edit }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exchanges/hbx_profiles/1
  # DELETE /exchanges/hbx_profiles/1.json
  def destroy
    @hbx_profile.destroy
    respond_to do |format|
      format.html { redirect_to exchanges_hbx_profiles_path, notice: 'HBX Profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def set_date
    forms_time_keeper = Forms::TimeKeeper.new(params[:forms_time_keeper])
    begin
      forms_time_keeper.set_date_of_record(forms_time_keeper.forms_date_of_record)
      flash[:notice] = "Date of record set to " + TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    rescue Exception=>e
      flash[:error] = "Failed to set date of record, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

private
  def agent_assistance_messages(params, agent, role)
    if params[:person].present?
      insured = Person.find(params[:person])
      first_name = insured.first_name
      last_name = insured.last_name
      name = insured.full_name
      insured_email = insured.emails.last.try(:address) || insured.try(:user).try(:email)
      root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + params[:person] +'&original_application_type:'
      text = "<br>Resume Application via "
      body = 
        "Please contact #{insured.first_name} #{insured.last_name}. <br/> " + 
        "Plan Shopping help request from Person Id #{insured.id}, email #{insured_email}.<br/>" +
        "Additional PII is SSN #{insured.ssn} and DOB #{insured.dob}.<br>" +
        "<a href='" + root+"phone'>#{text}phone</a>  <br>" +
        "<a href='" + root+"paper'>#{text}paper</a>  <br>"
    else
      first_name = params[:first_name]
      last_name = params[:last_name]
      name = first_name.to_s + ' ' + last_name.to_s 
      insured_email = params[:email]
      body =  "Please contact #{first_name} #{last_name}. <br/>" +
        "Plan shopping help has been requested by #{insured_email}<br>"
      body += "SSN #{params[:ssn]} <br>" if params[:ssn].present?
      body += "DOB #{params[:dob]} <br>" if params[:dob].present?
    end
    hbx_profile = HbxProfile.find_by_state_abbreviation('DC')
    message_params = {
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Please contact #{first_name} #{last_name}. ",
      body: body,
      }
    create_secure_message message_params, hbx_profile, :sent
    create_secure_message message_params, agent, :inbox
    result = UserMailer.new_client_notification(agent.user.email, first_name, name, role, insured_email, params[:person].present?)
    puts result.to_s if Rails.env.development?
   end  

  def find_hbx_profile
    @profile = current_user.person.try(:hbx_staff_role).try(:hbx_profile)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = HbxProfile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def organization_params
    params[:hbx_profile][:organization].permit(:organization_attributes)
  end

  def hbx_profile_params
    params[:hbx_profile].permit(:hbx_profile_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def call_customer_service(first_name, last_name)
    "No match found for #{first_name} #{last_name}.  Please call Customer Service at: (855)532-5465 for assistance.<br/>"
  end
end
