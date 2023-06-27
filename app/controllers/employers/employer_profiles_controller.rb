class Employers::EmployerProfilesController < Employers::EmployersController
  include ::Config::AcaConcern
  include ApplicationHelper
  include ResourceConfigurator

  before_action :redirect_new_model, only: [:welcome, :index, :new, :show_profile, :edit, :generate_sic_tree, :create]
  before_action :redirect_show, only: [:show]

  before_action :find_employer, only: [:show, :show_profile, :destroy, :inbox,
                                       :bulk_employee_upload, :bulk_employee_upload_form, :download_invoice, :export_census_employees, :link_from_quote, :new_document, :upload_document, :generate_checkbook_urls]

  before_action :check_show_permissions, only: [:show, :show_profile, :destroy, :inbox, :bulk_employee_upload, :bulk_employee_upload_form]
  before_action :check_index_permissions, only: [:index]
  before_action :check_employer_staff_role, only: [:new]
  before_action :check_access_to_organization, only: [:edit]
  before_action :check_and_download_invoice, only: [:download_invoice]
  around_action :wrap_in_benefit_group_cache, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:show], if: :check_origin?
  before_action :updateable?, only: [:create, :update]
  layout "two_column", except: [:new]

  def redirect_new_model
    redirect_to "/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor"
  end

  def redirect_show
    employer_profile = EmployerProfile.find(params[:id])
    hbx_id = employer_profile.hbx_id if employer_profile.present?
    organization = BenefitSponsors::Organizations::Organization.employer_by_hbx_id(hbx_id)
    if organization.present?
      employer_profile_id = organization.first.employer_profile.id.to_s
      redirect_to benefit_sponsors.profiles_employers_employer_profile_path(employer_profile_id, tab: 'home')
    else
      redirect_to "/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor"
    end
  end

  def link_from_quote
    claim_code = params[:claim_code].upcase
    import_roster = params[:import_roster] == "yes" ? true : false

    claim_code_status = Quote.claim_code_status?(claim_code)

    if claim_code_status == "invalid"
      flash[:error] = 'Quote claim code not found.'
    elsif claim_code_status == "claimed"
      flash[:error] = 'Quote claim code already claimed.'
    else
      if @employer_profile.build_plan_year_from_quote(claim_code, import_roster)
        flash[:notice] = 'Code claimed with success. Your Plan Year has been created.'
      else
        flash[:error] = 'There was issue claiming this quote.'
      end
    end

    redirect_to employers_employer_profile_path(@employer_profile, tab: 'benefits')
  end

  #Deprecated. Use new model version instead.
  def index
  end

  #Deprecated. Use new model version instead.
  def welcome
  end

  def search
    @employer_profile = Forms::EmployerCandidate.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def match
    @employer_candidate = Forms::EmployerCandidate.new(params.require(:employer_profile))
    if @employer_candidate.valid?
      found_employer = @employer_candidate.match_employer
      unless params["create_employer"].present?
        if found_employer.present?
          @employer_profile = found_employer
          respond_to do |format|
            format.js { render 'match' }
            format.html { render 'match' }
          end
        else
          respond_to do |format|
            format.js { render 'no_match' }
            format.html { render 'no_match' }
          end
        end
      else
        build_organization
        @employer_profile.attributes = params[:employer_profile]
        @organization.save(validate: false)
        build_office_location
        respond_to do |format|
          format.js { render "edit" }
          format.html { render "edit" }
        end
      end
    else
      @employer_profile = @employer_candidate
      respond_to do |format|
        format.js { render 'search' }
        format.html { render 'search' }
      end
    end
  end

  #Deprecated. Use new model version instead.
  def my_account
  end

  #Deprecated. Use new model version instead.
  def show
  end

  #Deprecated. Use new model version instead.
  def show_profile
  end



  def new
  end

  def edit
  end

  #Deprecated. Use new model version instead.
  def create
  end

  def show_pending
  end

  def generate_sic_tree
    sic_tree = SicCode.generate_sic_array
    render :json => sic_tree
  end

  def update
    sanitize_employer_profile_params
    @organization = Organization.find(params.permit(:id))

    #save duplicate office locations as json in case we need to refresh
    @organization_dup = @organization.office_locations.as_json
    @employer_profile = @organization.employer_profile
    @employer = @employer_profile.match_employer(current_user)
    if (current_user.has_employer_staff_role? && @employer_profile.staff_roles.include?(current_user.person)) || current_user.person.agent?
      @organization.assign_attributes(organization_profile_params)

      #clear office_locations, don't worry, we will recreate
      @organization.assign_attributes(:office_locations => [])
      @organization.save(validate: false)

      if @organization.update_attributes(employer_profile_params)
        @organization.notify_legal_name_or_fein_change
        @organization.notify_address_change(@organization_dup,employer_profile_params)
        flash[:notice] = 'Employer successfully Updated.'
        redirect_to edit_employers_employer_profile_path(@organization)
      else
        org_error_msg = @organization.errors.full_messages.join(",").humanize if @organization.errors.present?

        #in case there was an error, reload from saved json
        @organization.assign_attributes(:office_locations => @organization_dup)
        @organization.save(validate: false)
        #@organization.reload
        flash[:error] = "Employer information not saved. #{org_error_msg}."
        redirect_to edit_employers_employer_profile_path(@organization)
      end
    else
      flash[:error] = 'You do not have permissions to update the details'
      redirect_to edit_employers_employer_profile_path(@employer_profile)
    end
  end

  def inbox
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
    respond_to do |format|
      format.js { render 'inbox' }
      format.html { render 'inbox' }
    end
  end

  def consumer_override
    session[:person_id] = params['person_id']
    redirect_to family_account_path
  end

  #Deprecated. Use new model version instead.
  def export_census_employees
  end

  def bulk_employee_upload_form
  end


  def generate_checkbook_urls
    trigger_notice_observer(@employer_profile, @employer_profile, 'out_of_pocket_url_notifier')
    flash[:notice] = "Custom Plan Match instructions are being generated.  Check your secure Messages inbox shortly."
    redirect_to benefit_sponsors.profiles_employers_employer_profile_path(tab: 'employees')
  end

  def download_invoice
    options={}
    options[:content_type] = @invoice.type
    options[:filename] = @invoice.title
    send_data Aws::S3Storage.find(@invoice.identifier) , options
  end

  def bulk_employee_upload
    file = params.require(:file)
    @census_employee_import = CensusEmployeeImport.new({file:file, employer_profile:@employer_profile})
    begin
    if @census_employee_import.save
      redirect_to "/employers/employer_profiles/#{@employer_profile.id}?employer_profile_id=#{@employer_profile.id}&tab=employees", :notice=>"#{@census_employee_import.length} records uploaded from CSV"
    else
      render "employers/employer_profiles/employee_csv_upload_errors"
    end
    rescue Exception => e
      if e.message == "Unrecognized Employee Census spreadsheet format. Contact #{site_short_name} for current template."
        render "employers/employer_profiles/_download_new_template"
      else
        @census_employee_import.errors.add(:base, e.message)
        render "employers/employer_profiles/employee_csv_upload_errors"
      end
    end


  end

  def redirect_to_first_allowed
    redirect_to employers_employer_profile_path(:id => current_user.person.employer_staff_roles.first.employer_profile_id)
  end

  def new_document # Should be in ER attestations controller
    @document = @employer_profile.documents.new
    respond_to do |format|
      format.js #{ render "new_document" }
    end
  end

  def upload_document # Should be in ER attestations controller
    @employer_profile.upload_document(file_path(params[:file]),file_name(params[:file]),params[:subject],params[:file].size)
    redirect_to employers_employer_profile_path(:id => @employer_profile) + '?tab=documents'
  end

  def download_documents # Should be in ER attestations controller
    @employer_profile = EmployerProfile.find(params[:id])
    #begin
    doc = @employer_profile.documents.find(params[:ids][0])
    doc.present? ? (send_file doc.identifier, file_name: doc.title, content_type: doc.format) : nil

      #render json: { status: 200, message: 'Successfully submitted the selected employer(s) for binder paid.' }
    #rescue => e
    #  render json: { status: 500, message: 'An error occured while submitting employer(s) for binder paid.' }
    #end

    #render json: { status: 200, message: 'Successfully Downloaded.' }

  end

  def delete_documents
    @employer_profile = EmployerProfile.find(params[:id])
    begin
      @employer_profile.documents.any_in(:_id =>params[:ids]).destroy_all
      render json: { status: 200, message: 'Successfully submitted the selected employer(s) for binder paid.' }
    rescue => e
      render json: { status: 500, message: 'An error occured while submitting employer(s) for binder paid.' }
    end
  end

  #Deprecated. Use new model version instead.
  def counties_for_zip_code
  end

  # def employer_account_creation_notice
  #   begin
  #     ShopNoticesNotifierJob.perform_later(@organization.employer_profile.id.to_s, "employer_account_creation_notice")
  #   rescue Exception => e
  #     Rails.logger.error { "Unable to deliver Employer Notice to #{@organization.employer_profile.legal_name} due to #{e}" }
  #   end
  # end

  private

  def file_path(file)
    file.tempfile.path
  end

  def file_name(file)
    file.original_filename
  end

  def updateable?
    authorize EmployerProfile, :updateable?
  end

  def collect_and_sort_invoices(sort_order='ASC')
    @invoices = []
    @invoices << @employer_profile.organization.try(:documents).to_a
    invoice_documents = @employer_profile.documents.select{ |invoice| ["invoice", "initial_invoice"].include? invoice.subject }
    @invoices << invoice_documents if invoice_documents.present?
    @invoices.flatten!
    sort_order == 'ASC' ? @invoices.sort_by!(&:date) : @invoices.sort_by!(&:date).reverse! unless @documents
  end

  def check_and_download_invoice
    @invoice = @employer_profile.organization.invoices.select{ |inv| inv.id.to_s == params[:invoice_id]}.first
  end

  def sort_plan_years(plans)
    renewing_states = PlanYear::RENEWING_PUBLISHED_STATE + PlanYear::RENEWING
    renewing = plans.select { |plan_year| renewing_states.include? plan_year.aasm_state }
    ineligible_plans, active_plans = plans.partition { |plan_year| PlanYear::INELIGIBLE_FOR_EXPORT_STATES.include? plan_year.aasm_state }
    ineligible_plans = ineligible_plans.select { |plan_year| renewing.exclude? plan_year }
    active_plans = active_plans.partition { |plan_year| PlanYear::PUBLISHED.include? plan_year.aasm_state }.flatten
    active_plans = active_plans.select { |plan_year| renewing.exclude? plan_year }
    @plan_years = renewing + active_plans + ineligible_plans
  end

  def paginate_employees
    status_params = params.permit(:id, :status, :search)
    @status = status_params[:status] || 'active'
    @search = status_params[:search] || false
    #@avaliable_employee_names ||= @employer_profile.census_employees.sorted.map(&:full_name).map(&:strip).map {|name| name.squeeze(" ")}.uniq
    #@avaliable_employee_names ||= @employer_profile.census_employees.where(last_name: => /^#{page_no}/i).limit(20).map(&:full_name).map(&:strip).map {|name| name.squeeze(" ")}.uniq

    census_employees = case @status
                       when 'terminated'
                         @employer_profile.census_employees.terminated.sorted
                       when 'all'
                         @employer_profile.census_employees.sorted
                       when 'cobra'
                         @employer_profile.census_employees.by_cobra.sorted
                       else
                         @employer_profile.census_employees.active.sorted
                       end
    if params["employee_search"].present?
      query_string = CensusEmployee.search_hash(params["employee_search"])
      census_employees = census_employees.any_of(query_string)
    end
    @page_alphabets = page_alphabets(census_employees, "last_name")

    if params[:page].present?
      page_no = cur_page_no(@page_alphabets.first)
      @census_employees = census_employees.where("last_name" => /^#{Regexp.escape(page_no)}/i).page(params[:pagina])
      #@avaliable_employee_names ||= @census_employees.limit(20).map(&:full_name).map(&:strip).map {|name| name.squeeze(" ")}.uniq
    else
      @total_census_employees_quantity = census_employees.count
      @census_employees = census_employees.limit(20).to_a
      #@avaliable_employee_names ||= @census_employees.map(&:full_name).map(&:strip).map {|name| name.squeeze(" ")}.uniq
    end
  end

  def paginate_families
    #FIXME add paginate
    @employees = @employer_profile.employee_roles.select { |ee| CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include?(ee.census_employee.aasm_state)}
  end

  def check_employer_staff_role
    if current_user.person && current_user.person.has_active_employer_staff_role?
      redirect_to employers_employer_profile_path(:id => current_user.person.active_employer_staff_roles.first.employer_profile_id, :tab => "home")
    end
  end

  def find_mailbox_provider
    hbx_staff = current_user.person.hbx_staff_role
    if hbx_staff
      profile = current_user.person.hbx_staff_role.hbx_profile
    else
      broker_id = current_user.person.broker_role.broker_agency_profile_id.to_s
      profile = BrokerAgencyProfile.find(broker_id)
    end
    return profile
  end

  def check_show_permissions
    id_params = params.permit(:id, :employer_profile_id)
    id = id_params[:id] || id_params[:employer_profile_id]
    ep = EmployerProfile.find(id)
    policy = ::AccessPolicies::EmployerProfile.new(current_user)
    policy.authorize_show(ep, self)
  end

  def check_index_permissions
    policy = ::AccessPolicies::EmployerProfile.new(current_user)
    policy.authorize_index(params[:broker_agency_id], self)
  end

  def check_admin_staff_role
    if current_user.has_hbx_staff_role? || current_user.has_broker_agency_staff_role? || current_user.has_broker_role?
    elsif current_user.has_employer_staff_role?
      ep_id = current_user.person.employer_staff_roles.first.employer_profile_id
      if ep_id.to_s != params[:id].to_s
        redirect_to employers_employer_profile_path(:id => current_user.person.employer_staff_roles.first.employer_profile_id)
      end
    else
      redirect_to new_employers_employer_profile_path
    end
  end

  def check_access_to_organization
    id = params.permit(:id)[:id]
    organization = Organization.find(id)
    policy = ::AccessPolicies::EmployerProfile.new(current_user)
    policy.authorize_edit(organization.employer_profile, self)
  end

  def find_employer
    id_params = params.permit(:id, :employer_profile_id)
    id = id_params[:id] || id_params[:employer_profile_id]
    # Deprecate this after moving attestation actions to ER attestations controller
    @employer_profile = EmployerProfile.find(id) || BenefitSponsors::Organizations::Profile.find(id)
    render file: 'public/404.html', status: 404 if @employer_profile.blank?
  end

  def organization_profile_params
    params.require(:organization).permit(
      :id,
      :employer_profile_attributes => [:legal_name, :entity_kind, :dba, :sic_code]
    )
  end

  def employer_profile_params
    params.require(:organization).permit(
      :employer_profile_attributes => [ :entity_kind, :contact_method, :dba, :legal_name, :sic_code],
      :office_locations_attributes => [
        {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
        {:phone_attributes => [:kind, :area_code, :number, :extension]},
        {:email_attributes => [:kind, :address]},
        :is_primary
      ]
    )
  end

  def sanitize_employer_profile_params
    params[:organization][:office_locations_attributes].each do |key, location|
      params[:organization][:office_locations_attributes].delete(key) unless location['address_attributes']
      location.delete('phone_attributes') if (location['phone_attributes'].present? && location['phone_attributes']['number'].blank?)
      office_locations = params[:organization][:office_locations_attributes]
      if office_locations && office_locations[key]
        params[:organization][:office_locations_attributes][key][:is_primary] = (office_locations[key][:address_attributes][:kind] == 'primary')
      end
    end
  end

  def build_organization
    @organization = Organization.new
    @employer_profile = @organization.build_employer_profile
  end

  def build_employer_profile_params
    build_organization
    build_office_location
  end

  def build_office_location
    @organization.office_locations.build unless @organization.office_locations.present?
    office_location = @organization.office_locations.first
    office_location.build_address unless office_location.address.present?
    office_location.build_phone unless office_location.phone.present?
    @organization
  end

  def wrap_in_benefit_group_cache
#    prof_result = RubyProf.profile do
      Caches::RequestScopedCache.allocate(:employer_calculation_cache_for_benefit_groups)
      yield
      Caches::RequestScopedCache.release(:employer_calculation_cache_for_benefit_groups)
#    end
#    printer = RubyProf::MultiPrinter.new(prof_result)
#    printer.print(:path => File.join(Rails.root, "rprof"), :profile => "profile")
  end

  def employer_params
    params.permit(:first_name, :last_name, :dob)
  end

  def check_origin?
    request.referrer.present? and URI.parse(request.referrer).host == "app.dchealthlink.com"
  end

  def get_sic_codes
    @grouped_options = Caches::SicCodesCache.load
  end
end
