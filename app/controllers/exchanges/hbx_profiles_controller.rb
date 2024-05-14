class Exchanges::HbxProfilesController < ApplicationController
  include Exchanges::HbxProfilesHelper
  include ::DataTablesAdapter
  include ::DataTablesSearch
  include ::Pundit
  include ::SepAll
  include ::Config::AcaHelper
  include HtmlScrubberUtil

  before_action :permitted_params_family_index_dt, only: [:family_index_dt]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]
  before_action :find_hbx_profile, only: [:employer_index, :configuration, :broker_agency_index, :inbox, :show, :binder_index]
  before_action :find_benefit_sponsorship, only: [:oe_extendable_applications, :oe_extended_applications, :edit_open_enrollment, :extend_open_enrollment, :close_extended_open_enrollment, :edit_fein, :update_fein, :force_publish, :edit_force_publish]
  before_action :redirect_if_staff_tab_is_disabled, only: [:staff_index]
  before_action :set_cache_headers, only: [:show, :family_index_dt, :user_account_index, :identity_verification, :broker_agency_index, :outstanding_verification_dt, :configuration, :inbox]
  before_action :redirect_if_general_agency_is_disabled, only: [:general_agency_index]
  before_action :redirect_if_employer_datatable_is_disabled, only: [:employer_datatable]
  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  layout 'single_column'

  # SHOP Feature
  def oe_extendable_applications
    authorize HbxProfile, :oe_extendable_applications?

    @benefit_applications  = @benefit_sponsorship.oe_extendable_benefit_applications
    @element_to_replace_id = params[:employer_actions_id]
  end

  # SHOP Feature
  def oe_extended_applications
    authorize HbxProfile, :oe_extended_applications?

    @benefit_applications  = @benefit_sponsorship.oe_extended_applications
    @element_to_replace_id = params[:employer_actions_id]
  end

  # SHOP Feature
  def edit_open_enrollment
    authorize HbxProfile, :edit_open_enrollment?

    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
  end

  # SHOP Feature
  def extend_open_enrollment
    authorize HbxProfile, :extend_open_enrollment?

    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
    open_enrollment_end_date = Date.strptime(params["open_enrollment_end_date"], "%m/%d/%Y")
    ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application).extend_open_enrollment(open_enrollment_end_date)
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "Successfully extended employer(s) open enrollment." }
  end

  # SHOP Feature
  def close_extended_open_enrollment
    authorize HbxProfile, :close_extended_open_enrollment?

    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
    ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application).end_open_enrollment(TimeKeeper.date_of_record)
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "Successfully closed employer(s) open enrollment." }
  end

  # SHOP Feature
  def new_benefit_application
    authorize HbxProfile, :new_benefit_application?

    @ba_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(new_ba_params)
    @element_to_replace_id = params[:employer_actions_id]
  end

  # SHOP Feature
  def create_benefit_application
    authorize HbxProfile, :create_benefit_application?

    @ba_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(create_ba_params)
    authorize @ba_form, :updateable?
    @save_errors = benefit_application_error_messages(@ba_form) unless @ba_form.save
    @element_to_replace_id = params[:employer_actions_id]
  end

  # SHOP Feature
  def edit_fein
    authorize HbxProfile, :edit_fein?

    @organization = @benefit_sponsorship.organization
    @element_to_replace_id = params[:employer_actions_id]

    respond_to do |format|
      format.js { render "edit_fein" }
    end
  end

  # SHOP Feature
  def update_fein
    authorize HbxProfile, :update_fein?

    @organization = @benefit_sponsorship.organization
    @element_to_replace_id = params[:employer_actions_id]
    service_obj = ::BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship: @benefit_sponsorship)
    update_fein_result_array = service_obj.update_fein(params['organizations_general_organization']['new_fein'])
    @result = update_fein_result_array[0]
    @errors_on_save = update_fein_result_array[1]
    if @errors_on_save
      respond_to { |format| format.js { render 'edit_fein' } }
    else
      respond_to { |format| format.js { render 'update_fein' } }
    end
  end

  # SHOP Feature
  def binder_paid
    authorize HbxProfile, :binder_paid?

    if params[:ids]
      begin
        ::BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.set_binder_paid(params[:ids])
        flash["notice"] = "Successfully submitted the selected employer(s) for binder paid."
        render json: { status: 200, message: 'Successfully submitted the selected employer(s) for binder paid.' }
      rescue => e
        render json: { status: 500, message: 'An error occured while submitting employer(s) for binder paid.' }
      end
    end
    # Removed redirect because of Datatables. Send Results to Datatable Status
    #redirect_to exchanges_hbx_profiles_root_path
  end

  def new_secure_message
    authorize HbxProfile, :new_secure_message?

    @resource = get_resource_for_secure_form(params)
    @element_to_replace_id = params[:employer_actions_id] || params[:family_actions_id]

    respond_to :js
  end

  def create_send_secure_message
    authorize HbxProfile, :create_send_secure_message?

    @resource = get_resource(params)
    @subject = params[:subject].presence
    @body = params[:body].presence
    @element_to_replace_id = params[:actions_id]
    if params[:file].present? && !valid_file_upload?(params[:file], FileUploadValidator::VERIFICATION_DOC_TYPES)
      redirect_to family_index_dt_exchanges_hbx_profiles_path
      return
    end
    result = ::Operations::SecureMessageAction.new.call(
      params: params.permit(:actions_id, :body, :file, :resource_name, :resource_id, :subject, :controller).to_h,
      user: current_user
    )
    @error_on_save = result.failure if result.failure?
    respond_to do |format|
      if @error_on_save
        format.js { render "new_secure_message"}
      else
        format.js { "Message Sent successfully"  }
      end
    end
  end

  # SHOP Feature
  def disable_ssn_requirement
    authorize HbxProfile, :disable_ssn_requirement?

    @benfit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => params[:ids])

    @benfit_sponsorships.each do |benfit_sponsorship|
      # logic for both Bulk Action drop down and action column drop down under data table
      if params[:can_update].present?
        if params[:can_update] == "disable"
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: true, ssn_disabled_on: TimeKeeper.datetime_of_record)
        else
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: false, ssn_enabled_on: TimeKeeper.datetime_of_record)
        end
      else
        if !benfit_sponsorship.is_no_ssn_enabled
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: true, ssn_disabled_on: TimeKeeper.datetime_of_record)
        else
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: false, ssn_enabled_on: TimeKeeper.datetime_of_record)
        end
      end
    end
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "SSN/TIN requirement has been successfully updated for the roster of selected employer" }
  end

  # SHOP Feature
  def generate_invoice
    authorize HbxProfile, :generate_invoice?

    @benfit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => params[:ids])
    @organizations = @benfit_sponsorships.map(&:organization)
    @employer_profiles = @organizations.flat_map(&:employer_profile)
    @employer_profiles.each do |employer_profile|
      employer_profile.trigger_model_event(:generate_initial_employer_invoice)
    end

    flash["notice"] = "Successfully submitted the selected employer(s) for invoice generation."
    #redirect_to exchanges_hbx_profiles_root_path

     respond_to do |format|
       format.js
     end
  end

  # SHOP Feature
  def edit_force_publish
    authorize HbxProfile, :edit_force_publish?

    @element_to_replace_id = params[:employer_actions_id]
    @benefit_application = @benefit_sponsorship.benefit_applications.draft_state.last

    respond_to do |format|
     format.js
   end
  end

  # SHOP Feature
  def force_publish
    authorize HbxProfile, :force_publish?

    @element_to_replace_id = params[:employer_actions_id]
    @benefit_application   = @benefit_sponsorship.benefit_applications.draft_state.last

    if @benefit_application.present?
      @service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application)
      if @service.may_force_submit_application? || params[:publish_with_warnings] == 'true'
        @service.force_submit_application
      end
    end

    respond_to do |format|
      format.js
    end
  end

  # SHOP Feature
  def employer_invoice
    authorize HbxProfile, :employer_invoice?

    # Dynamic Filter values for upcoming 30, 60, 90 days renewals
    @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
    @next_60_day = @next_30_day.next_month
    @next_90_day = @next_60_day.next_month

    @datatable = Effective::Datatables::BenefitSponsorsEmployerDatatable.new

    respond_to do |format|
      format.js
    end
  end

  # SHOP Feature
  def employer_datatable
    authorize HbxProfile, :employer_datatable?

    @datatable = Effective::Datatables::BenefitSponsorsEmployerDatatable.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/invoice.html.slim' }
      # TODO: Consider adding the following after the format.html.
      # Look at ticket 40578 and associated PR for reference.
      # format.js
    end
  end

 #  def employer_poc
 #    authorize HbxProfile, :employer_poc?


 #    # Dynamic Filter values for upcoming 30, 60, 90 days renewals
 #    @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
 #    @next_60_day = @next_30_day.next_month
 #    @next_90_day = @next_60_day.next_month

 #    @datatable = Effective::Datatables::EmployerDatatable.new
 #    render '/exchanges/hbx_profiles/employer_poc'
 # #   respond_to do |format|
 #  #    format.html
 #   #   format.js
 #   # end
 #  end

  def staff_index
    authorize HbxProfile, :staff_index?

    @q = params.permit(:q)[:q]
    @staff = Person.where(:$or => [{csr_role: {:$exists => true}}, {assister_role: {:$exists => true}}])
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = page_no.present? ? @staff.where(last_name: /^#{Regexp.escape(page_no)}/i) : []
    else
      @staff = @staff.where(last_name: @q)
    end
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/staff.html.erb' }
    end
  end

  def assister_index
    authorize HbxProfile, :assister_index?

    @q = params.permit(:q)[:q]
    @staff = Person.where(assister_role: {:$exists =>true})
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{Regexp.escape(page_no)}/i)
    else
      @staff = @staff.where(last_name: @q)
    end

    respond_to :js
  end

  def request_help
    raise ActionController::UnknownFormat unless request.format.html?

    insured = Person.where(_id: params[:person]).first
    authorize insured.primary_family, :request_help?

    role = nil
    consumer = nil
    if params[:type]
      cac_flag = params[:type] == 'CAC'
      match = CsrRole.find_by_name(params[:firstname], params[:lastname], cac_flag)
      if match.any?
        agent = match.first
        role = cac_flag ? 'Certified Applicant Counselor' : 'Customer Service Representative'
      end
    else
      if params[:broker].present?
        agent = Person.find(params[:broker])
        broker_role_id = agent.broker_role.id
        consumer = Person.find(params[:person])
        family = consumer.primary_family
        authorize family, :hire_broker_agency?
        family.hire_broker_agency(broker_role_id)
        role = l10n("broker")
      else
        agent = Person.find(params[:assister])
        role = 'In-Person Assister'
      end
    end
    if role
      status_text = 'Message sent to ' + role + ' ' + agent.full_name + ' <br>'
      if find_email(agent, role)
        params.merge!(consumer_person_id: consumer.id.to_s) if consumer.present?
        agent_assistance_messages(params,agent,role)
      else

        status_text = "Agent has no email.   Please select another"
      end
    else
      status_text = call_customer_service params[:firstname].strip, params[:lastname].strip
    end
    @person = Person.find(params[:person])
    broker_view = render_to_string 'insured/families/_consumer_brokers_widget', :layout => false

    render :plain => {broker: broker_view, status: status_text}.to_json, layout: false
  end

  def family_index
    authorize HbxProfile, :family_index?

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
      format.js
    end
  end

  def family_index_dt
    authorize HbxProfile, :family_index_dt?

    @selector = params[:scopes][:selector] if params[:scopes].present?
    @datatable = Effective::Datatables::FamilyDataTable.new(permitted_params_family_index_dt.to_h)
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/family_index_datatable" }
    end
  end

  def identity_verification
    authorize HbxProfile, :identity_verification?

    @datatable = Effective::Datatables::IdentityVerificationDataTable.new(params[:scopes])
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/identity_verification_datatable.html.erb" }
    end
  end

  def user_account_index
    authorize HbxProfile, :user_account_index?

    @datatable = Effective::Datatables::UserAccountDatatable.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/user_account_index_datatable.html.slim' }
    end
  end

  def outstanding_verification_dt
    authorize HbxProfile, :outstanding_verification_dt?

    @selector = params[:scopes][:selector] if params[:scopes].present?
    @datatable = Effective::Datatables::OutstandingVerificationDataTable.new(params[:scopes])
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/outstanding_verification_datatable.html.erb" }
    end
  end

  def hide_form
    authorize HbxProfile, :hide_form?

    @element_to_replace_id = params[:family_actions_id]

    respond_to :js
  end

  def add_sep_form
    authorize HbxProfile, :add_sep_form?

    getActionParams
    @element_to_replace_id = params[:family_actions_id]

    respond_to :js
  end

  def show_sep_history
    authorize HbxProfile, :show_sep_history?

    getActionParams
    @element_to_replace_id = params[:family_actions_id]

    respond_to :js
  end

  # SHOP and IVL Feature
  def get_user_info
    authorize HbxProfile, :get_user_info?

    # from benefit_sponsors_employer_datatable
    @element_to_replace_id = params[:family_actions_id] || params[:employer_actions_id]
    if params[:person_id].present?
      @person = Person.find(params[:person_id])
    else
      @employer_actions = true
      @people = Person.where(:id => { "$in" => (params[:people_id] || []) })
      @organization = if params.key?(:employer_actions_id)
        BenefitSponsors::Organizations::Profile.find(@element_to_replace_id.split("_").last).organization
      else
        BenefitSponsors::Organizations::Organization.find(@element_to_replace_id.split("_").last)
      end
    end

    respond_to :js
  end

  def update_effective_date
    authorize HbxProfile, :update_effective_date?

    @qle = QualifyingLifeEventKind.find(params[:id])
    respond_to do |format|
      format.js {}
    end
    calculate_rule
  end

  def calculate_sep_dates
    authorize HbxProfile, :calculate_sep_dates?

    calculateDates
    respond_to :js
  end

  def add_new_sep
    authorize HbxProfile, :add_new_sep?

    @element_to_replace_id = sep_params[:family_actions_id]
    createSep
    respond_to do |format|
      format.js { render "sep/approval/add_sep_result.js.erb", name: @name }
    end
  end

  def cancel_enrollment
    authorize HbxProfile, :cancel_enrollment?

    @hbxs = Family.find(params[:family]).all_enrollments.cancel_eligible
    @row = params[:family_actions_id]
    respond_to do |format|
      format.js { render "datatables/cancel_enrollment" }
    end
  end

  def update_cancel_enrollment
    authorize HbxProfile, :update_cancel_enrollment?

    params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(uniq_cancel_params).to_h)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.cancel_enrollments
    respond_to do |format|
      format.js { render "datatables/cancel_enrollment_result.js.erb"}
    end
  end

  def terminate_enrollment
    authorize HbxProfile, :terminate_enrollment?

    @hbxs = Family.find(params[:family]).all_enrollments.can_terminate
    @row = params[:family_actions_id]
    respond_to do |format|
      format.js { render "datatables/terminate_enrollment" }
    end
  end

  def update_terminate_enrollment
    authorize HbxProfile, :update_terminate_enrollment?

    params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(uniq_terminate_params).to_h)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.terminate_enrollments
    respond_to do |format|
      format.js { render "datatables/terminate_enrollment_result.js.erb"}
    end
  end

  # drop action
  def drop_enrollment_member
    authorize HbxProfile, :drop_enrollment_member?

    @admin_permission = params[:admin_permission]
    @hbxs = Family.find(params[:family]).all_enrollments.individual_market.can_terminate.select{ |enr| enr.hbx_enrollment_members.count > 1 }
    @row = params[:family_actions_id]
    respond_to do |format|
      format.js { render "datatables/drop_enrollment_member" }
    end
  end

  def update_enrollment_member_drop
    authorize HbxProfile, :update_enrollment_member_drop?

    params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(uniq_enrollment_member_drop_params).to_h)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.drop_enrollment_members
    respond_to do |format|
      format.js { render "datatables/drop_enrollment_member_result.js.erb"}
    end
  end

  def view_enrollment_to_update_end_date
    authorize HbxProfile, :view_enrollment_to_update_end_date?

    @person = Person.find(params[:person_id])
    @row = params[:family_actions_id]
    @element_to_replace_id = params[:family_actions_id]
    @enrollments = @person.primary_family.terminated_and_expired_enrollments
    @coverage_ended_enrollments = @person.primary_family.hbx_enrollments.where(:aasm_state.in=> ["coverage_terminated", "coverage_termination_pending", "coverage_expired"])
    @dup_enr_ids = fetch_duplicate_enrollment_ids(@coverage_ended_enrollments).map(&:to_s)

    respond_to :js
  end

  def update_enrollment_terminated_on_date
    authorize HbxProfile, :update_enrollment_terminated_on_date?

    begin
      @row = params[:family_actions_id]
      @element_to_replace_id = params[:family_actions_id]
      result = Operations::HbxEnrollments::EndDateChange.new.call(params: params)
      if result.success?
        respond_to do |format|
          format.js
        end
      else
        message = {notice: "Unable to find/update Enrollment."}
        redirect_to exchanges_hbx_profiles_root_path, flash: message
      end
    rescue Exception => e
      message = {error: e.to_s}
    end
  end

  def broker_agency_index
    authorize HbxProfile, :broker_agency_index?

    @datatable = Effective::Datatables::BrokerAgencyDatatable.new

    respond_to do |format|
      format.html { render 'exchanges/hbx_profiles/broker_agency_index_datatable.html.slim' }
    end
  end

  def general_agency_index
    authorize HbxProfile, :general_agency_index?

    page_string = params.permit(:gas_page)[:gas_page]
    page_no = page_string.blank? ? nil : page_string.to_i

    status_params = params.permit(:status)
    @status = status_params[:status] || 'is_applicant'
    @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.filter_by(@status)
    @general_agency_profiles = Kaminari.paginate_array(@general_agency_profiles).page(page_no)

    respond_to do |format|
      format.html { render "exchanges/hbx_profiles/general_agency_index.html.slim" }
      format.js
    end
  end

  def configuration
    authorize HbxProfile, :configuration?

    @time_keeper = Forms::TimeKeeper.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/configuration_index.html.erb' }
    end
  end

  def view_terminated_hbx_enrollments
    authorize HbxProfile, :view_terminated_hbx_enrollments?

    @person = Person.find(params[:person_id])
    @element_to_replace_id = params[:family_actions_id]
    @enrollments = @person.primary_family.terminated_and_expired_enrollments

    respond_to :js
  end

  def reinstate_enrollment
    authorize HbxProfile, :reinstate_enrollment?

    enrollment = HbxEnrollment.find(params[:enrollment_id].strip)

    if enrollment.present?
      begin
        reinstated_enrollment = enrollment.reinstate(edi: params['edi_required'].present?)
        @element_to_replace_id = params[:family_actions_id]
        if reinstated_enrollment.present?
          if params['comments'].present?
            reinstated_enrollment.comments.create(:content => params[:comments].strip, :user => current_user.id)
          end
          respond_to do |format|
            format.js
          end
        end
      rescue Exception => e
        message = {error: e.to_s}
      end
    else
      message = {notice: "Unable to find Enrollment."}
      redirect_to exchanges_hbx_profiles_root_path, flash: message
    end
  end

  def edit_dob_ssn
    authorize HbxProfile, :edit_dob_ssn?

    @person = Person.find(params[:id])
    @element_to_replace_id = params[:family_actions_id]
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, person_has_active_enrollment: @person_has_active_enrollment}
    end
  end

  def verify_dob_change
    authorize HbxProfile, :verify_dob_change?

    @person = Person.find(params[:person_id])
    @element_to_replace_id = params[:family_actions_id]
    @premium_implications = Person.dob_change_implication_on_active_enrollments(@person, params[:new_dob])
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, :new_ssn => params[:new_ssn], :new_dob => params[:new_dob],  :family_actions_id => params[:family_actions_id]}
    end
  end

  def update_dob_ssn
    authorize HbxProfile, :update_dob_ssn?

    @element_to_replace_id = params[:person][:family_actions_id]
    @person = Person.find(params[:person][:pid]) if !params[:person].blank? && !params[:person][:pid].blank?
    @ssn_match = Person.find_by_ssn(params[:person][:ssn]) unless params[:person][:ssn].blank?
    @ssn_fields = @person.employee_roles.map{|e| e.census_employee.is_no_ssn_allowed?} if @person.active_employee_roles.present?

    @ssn_require = @ssn_fields.present? && @ssn_fields.include?(false)
    if !@ssn_match.blank? && (@ssn_match.id != @person.id) # If there is a SSN match with another person.
      @dont_allow_change = true
    else
      result = ::Operations::UpdateDobSsn.new.call(person_id: @person.id, params: params, current_user: current_user, ssn_require: @ssn_require)
      @error_on_save, @dont_update_ssn = result.failure? ? result.failure : result.success
    end
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, :family_actions_id => params[:person][:family_actions_id]  } if @error_on_save
      format.js { render "update_enrollment", person: @person, :family_actions_id => params[:person][:family_actions_id] }
    end
  end

  def new_eligibility
    authorize HbxProfile, :new_eligibility?

    @person = Person.find(params[:person_id])
    @family = @person.primary_family
    @element_to_replace_id = params[:family_actions_id]
    @tax_household_group_data = JSON.parse(params[:tax_household_group_data]) if params[:tax_household_group_data].present?
    respond_to do |format|
      format.js { render "new_eligibility", person: @person, :family_actions_id => params[:family_actions_id]  }
    end
  end

  def process_eligibility
    authorize HbxProfile, :process_eligibility?

    @element_to_replace_id = params[:person][:family_actions_id]
    @person_id = params[:person][:person_id]
    @data = params.require(:person).permit(family_members: {}).to_h[:family_members]
    @tax_household_group_data = @data.inject({}) do |result, fm_hash|
      fm_info = fm_hash[1]
      family_member_id = fm_hash[0]

      result[fm_info[:tax_group]] ||= []

      result[fm_info[:tax_group]] << {
        pdc_type: fm_info[:pdc_type],
        csr: fm_info[:csr],
        is_filer: fm_info[:is_filer],
        member_name: fm_info[:member_name],
        family_member_id: family_member_id
      }

      result
    end

    respond_to do |format|
      format.js { render "process_eligibility" }
    end
  end

  def create_eligibility
    authorize HbxProfile, :create_eligibility?

    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      @element_to_replace_id = params[:tax_household_group][:family_actions_id]
      family = Person.find(params[:tax_household_group][:person_id]).primary_family
      ::Operations::TaxHouseholdGroups::CreateEligibility.new.call({
                                                                     family: family,
                                                                     th_group_info: params.require(:tax_household_group).permit(
                                                                       :person_id,
                                                                       :family_actions_id,
                                                                       :effective_date,
                                                                       :tax_households => {}
                                                                     ).to_h
                                                                   })
    else
      @element_to_replace_id = params[:person][:family_actions_id]
      family = Person.find(params[:person][:person_id]).primary_family
      family.active_household.create_new_tax_household(params[:person])
    end

    respond_to :js
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show
    if current_user.has_csr_role? || current_user.try(:has_assister_role?)
      redirect_to home_exchanges_agents_path
      return
    end
    authorize HbxProfile, :show?

    session[:person_id] = nil
    session[:dismiss_announcements] = nil
    @unread_messages = @profile.inbox.unread_messages.try(:count) || 0
  end

  def inbox
    authorize HbxProfile, :inbox?

    respond_to do |format|
      format.html { render "exchanges/hbx_profiles/inbox_messages.html.slim" }
    end
  end

  def set_date
    authorize HbxProfile, :modify_admin_tabs?
    forms_time_keeper = Forms::TimeKeeper.new(timekeeper_params.to_h)
    begin
      forms_time_keeper.set_date_of_record(forms_time_keeper.forms_date_of_record)
      flash[:notice] = "Date of record set to " + TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    rescue Exception=>e
      flash[:error] = "Failed to set date of record, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

  # Enrollments for APTC / CSR
  def aptc_csr_family_index
    authorize HbxProfile, :aptc_csr_family_index?

    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.all_active_assistance_receiving_for_current_year.page page_no
      @total = Family.all_active_assistance_receiving_for_current_year.count
    else
      person_ids = Person.search(@q).map(&:_id)

      total_families = Family.all_active_assistance_receiving_for_current_year.in("family_members.person_id" => person_ids).entries
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      #format.html { render "insured/families/aptc_csr_listing" }
      format.js {}
    end
  end

  def update_setting
    authorize HbxProfile, :update_setting?

    setting_record = Setting.where(name: setting_params[:name]).last

    begin
      setting_record.update(value: setting_params[:value]) if setting_record.present?
    rescue Exception => e
      flash[:error] = "Failed to update setting, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path

  end

  private

  def find_email(agent, role)
    if role == l10n("broker")
      agent.try(:broker_role).try(:email).try(:address)
    else
      agent.try(:user).try(:email)
    end
  end

  def redirect_if_employer_datatable_is_disabled
    redirect_to(exchanges_hbx_profiles_root_path, alert: l10n('insured.employer_datatable_disabled_warning')) unless EnrollRegistry.feature_enabled?(:aca_shop_market)
  end

  def redirect_if_general_agency_is_disabled
    redirect_to(exchanges_hbx_profiles_root_path, alert: l10n('insured.general_agency_index_disabled_warning')) unless EnrollRegistry.feature_enabled?(:general_agency)
  end

  def redirect_if_staff_tab_is_disabled
    redirect_to(main_app.root_path, notice: l10n("staff_index_not_enabled")) unless EnrollRegistry.feature_enabled?(:staff_tab)
  end

  def group_enrollments_by_year_and_market(all_enrollments)
    current_year = TimeKeeper.date_of_record.year
    years = ((current_year - 4)..(current_year + 1))

    years.inject({}) do |hash_map, year|
      ivl_enrs = all_enrollments.select{ |enrollment| !enrollment.is_shop? && enrollment.effective_on.year == year }
      shop_enrs = all_enrollments.select do |enrollment|
        next unless enrollment.present? || enrollment.sponsored_benefit_package.present?

        enrollment.is_shop? && enrollment.sponsored_benefit_package.start_on.year == year
      end
      hash_map["ivl_#{year}"] = ivl_enrs if ivl_enrs.present?
      hash_map["shop_#{year}"] = shop_enrs if shop_enrs.present?
      hash_map
    end
  end

  def get_duplicate_enrs(dup_enrollments)
    product_ids = dup_enrollments.flatten.pluck(:product_id)
    return [] if product_ids.uniq.count == product_ids.count

    product_ids.uniq.inject([]) do |array_of_arrays, product_id|
      current_enr = dup_enrollments.detect{ |en| en.product_id == product_id}
      dup_enrs =  if current_enr.is_shop?
                    dup_enrollments.select do |enr|
                      (enr.subscriber.applicant_id == current_enr.subscriber.applicant_id) &&
                        (enr.market_name == current_enr.market_name) &&
                        (enr.product.id == current_enr.product.id) &&
                        (enr.employer_profile.id == current_enr.employer_profile.id) &&
                        (enr.sponsored_benefit_package.start_on == current_enr.sponsored_benefit_package.start_on)
                    end
                  else
                    dup_enrollments.select do |enr|
                      (enr.subscriber.applicant_id == current_enr.subscriber.applicant_id) &&
                        (enr.market_name == current_enr.market_name) &&
                        (enr.product.id == current_enr.product.id)
                    end
                  end
      array_of_arrays = dup_enrs.to_a if dup_enrs.count > 1
      array_of_arrays
    end
  end

  def fetch_duplicate_enrollment_ids(enrollments)
    enrs_mapping_by_year_and_market = group_enrollments_by_year_and_market(enrollments)
    return [] if enrs_mapping_by_year_and_market.blank?

    enrs_mapping_by_year_and_market.inject([]) do |duplicate_ids, (market_year, enrollments)|
      next duplicate_ids unless enrollments.count > 1
      dups = get_duplicate_enrs(enrollments)
      next duplicate_ids if dups.empty?
      effective_date = dups.map(&:effective_on).max
      dups.each do |enr|
        duplicate_ids << enr.id if enr.effective_on < effective_date
      end
      duplicate_ids
    end
  end

  def permitted_params_family_index_dt
    params.permit(:scopes)
  end

  def uniq_terminate_params
    params.keys.map { |key| key.match(/terminate_hbx_.*/) || key.match(/termination_date_.*/) || key.match(/transmit_hbx_.*/) || key.match(/family_.*/) }.compact.map(&:to_s)
  end

  def uniq_enrollment_member_drop_params
    params.keys.map { |key| key.match(/terminate_member_.*/) || key.match(/termination_date_.*/) || key.match(/family_.*/) || key.match(/enrollment_id/) || key.match(/transmit_hbx_.*/) || key.match(/admin_permission/) }.compact.map(&:to_s)
  end

  def uniq_cancel_params
    params.keys.map { |key| key.match(/cancel_hbx_.*/) || key.match(/cancel_date_.*/) || key.match(/transmit_hbx_.*/) || key.match(/family_.*/) }.compact.map(&:to_s)
  end

  def get_resource(params)
    return nil if params[:resource_id].blank?

    case params[:resource_name]
    when 'Person'
      Person.find(params[:resource_id])
    else
      BenefitSponsors::Organizations::Profile.find(params[:resource_id])
    end
  end

  def get_resource_for_secure_form(params)
    if params[:person_id].present?
      Person.find(params[:person_id])
    elsif params[:profile_id].present?
      BenefitSponsors::Organizations::Profile.find(params[:profile_id])
    end
  end

  def benefit_application_error_messages(obj)
    obj.errors.full_messages.collect { |error| sanitize_html("<li>#{error}</li>") }
  end

  def new_ba_params
    params.merge!({ admin_datatable_action: true }).permit(:benefit_sponsorship_id, :admin_datatable_action)
  end

  def create_ba_params
    params.merge!({ pte_count: '0', msp_count: '0', admin_datatable_action: true })
    params.permit(:start_on, :end_on, :fte_count, :pte_count, :msp_count,
                  :open_enrollment_start_on, :open_enrollment_end_on, :benefit_sponsorship_id, :admin_datatable_action, :has_active_ba)
  end

  def sep_params
    params.except(:utf8, :commit).permit(:market_kind, :person, :firstName, :lastName, :family_actions_id,
                                         :effective_on_kind, :qle_id, :event_date, :effective_on_date, :csl_num,
                                         :start_on, :end_on, :next_poss_effective_date, :option1_date, :option2_date, :option3_date, :admin_comment, :coverage_renewal_flag)
  end

  def timekeeper_params
    params.require(:forms_time_keeper).permit(:date_of_record)
  end

  def modify_admin_tabs?
    authorize HbxProfile, :modify_admin_tabs?
  end

  def view_admin_tabs?
    authorize HbxProfile, :view_admin_tabs?
  end

  def setting_params
    params.require(:setting).permit(:name, :value)
  end

  def agent_assistance_messages(params, agent, role)
    # Merged the consumer_person_id elsewhere
    # To assure it doesn't acidentally confuse impersonation
    insured = if params[:consumer_person_id].present?
                Person.where(_id: params[:consumer_person_id]).first
              else
                Person.where(_id: params[:person]).first
              end
    first_name = insured.first_name || params[:first_name]
    last_name = insured.last_name || params[:last_name]
    insured_email = insured.emails.last.try(:address) || insured.try(:user).try(:email) || ""
    insured_phone_number = insured&.phones&.first&.full_phone_number
    insured_id = insured&.id&.to_s || params[:person]
    root = if insured_id
             "http://#{request.env['HTTP_HOST']}/exchanges/agents/resume_enrollment?person_id=#{insured_id}&original_application_type:"
           else
             ""
           end
    translation_key = "inbox.agent_assistance_secure_message"
    translation_interpolated_keys = {
      first_name: first_name,
      last_name: last_name,
      href_root: root,
      site_home_business_url: EnrollRegistry[:enroll_app].setting(:home_business_url).item,
      site_short_name: site_short_name,
      contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item.to_s,
      contact_center_tty_number: EnrollRegistry[:enroll_app].setting(:contact_center_tty_number).item.to_s
    }
    translation_interpolated_keys.merge!(insured_phone_number: insured_phone_number || '', insured_email: insured_email || '')
    body = sanitize_html(l10n(translation_key, translation_interpolated_keys))
    hbx_profile = HbxProfile.find_by_state_abbreviation(aca_state_abbreviation)
    message_params = {
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Please contact #{first_name} #{last_name}.",
      body: body
    }
    create_secure_message message_params, hbx_profile, :sent
    create_secure_message message_params, agent, :inbox
    hbx_id = insured&.hbx_id || ""
    agent_email = find_email(agent,role)
    full_name = "#{first_name} #{last_name}"
    if agent_email.present?
      agent_first_name = agent.first_name
      result = UserMailer.new_client_notification(agent_email, agent_first_name, role, insured_email, hbx_id)
      result.deliver_now
      puts result.to_s if Rails.env.development?
    else
      Rails.logger.warn("No email found for #{full_name} with hbx_id #{hbx_id}")
    end
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

  def check_csr_or_hbx_staff
    unless current_user.has_hbx_staff_role? || (current_user.person.csr_role && !current_user.person.csr_role.cac)
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member or a CSR" }
    end
  end

  def authorize_for_instance
    authorize @hbx_profile, "#{action_name}?".to_sym
  end

  def call_customer_service(first_name, last_name)
    "No match found for #{first_name} #{last_name}.  Please call Customer Service at: (855)532-5465 for assistance.<br/>"
  end

  def find_benefit_sponsorship
    @benefit_sponsorship = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id] || params[:id])
    raise "Unable to find benefit sponsorship" if @benefit_sponsorship.blank?
  end
end
