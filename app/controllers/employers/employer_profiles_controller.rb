class Employers::EmployerProfilesController < ApplicationController
  before_action :find_employer, only: [:show, :show_profile, :destroy, :inbox]
  before_action :check_admin_staff_role, only: [:index]
  before_action :check_employer_staff_role, only: [:new]

  def index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)

    if current_user.person.try(:broker_role)
      broker_id = current_user.person.broker_role.broker_agency_profile_id.to_s
      profile = BrokerAgencyProfile.find(broker_id)
      @orgs = Organization.where({'employer_profile.broker_agency_accounts.broker_agency_profile_id' => profile._id})
    end
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @profile = find_mailbox_provider
    @employer_profiles = @organizations.map {|o| o.employer_profile}
  end

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
        params.permit!
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

  def my_account
  end

  def show
    paginate_employees
    set_show_variables
  end

  def show_profile
    @tab = params['tab']
    paginate_employees
    set_show_variables
  end

  def new
    @organization = Forms::EmployerProfile.new
  end

  def create
    params.permit!
    @organization = Forms::EmployerProfile.new(params[:organization])
    if @organization.save(current_user)
      redirect_to employers_employer_profile_path(@organization.employer_profile)
    else
      render action: "new"
    end
  end

  def update
    @organization = Organization.find(params[:id])
    @employer_profile = @organization.employer_profile
    current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
    current_user.person.employer_contact = @employer_profile
    if !@employer_profile.owner.present? && @organization.update_attributes(employer_profile_params) && current_user.save
      current_user.person.employer_staff_roles << EmployerStaffRole.create(person: current_user.person, employer_profile_id: @employer_profile.id, is_owner: true)
      flash[:notice] = 'Employer successfully created.'
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      respond_to do |format|
        format.js { render "edit" }
        format.html { render "edit" }
      end
    end
  end

  def inbox
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
  end

  def consumer_override
    session[:person_id] = params['person_id']
    redirect_to home_consumer_profiles_path
  end

  private
    def paginate_employees
      status_params = params.permit(:id, :status)
      @status = status_params[:status] || 'active'

      census_employees = case @status
      when 'waived'
        @employer_profile.census_employees.waived.sorted
      when 'terminated'
        @employer_profile.census_employees.terminated.sorted
      when 'all'
        @employer_profile.census_employees.sorted
      else
        @employer_profile.census_employees.active.sorted
      end
      @page_alphabets = page_alphabets(census_employees, "last_name")
      if params[:page].present?
        page_no = cur_page_no(@page_alphabets.first)
        @census_employees = census_employees.where("last_name" => /^#{page_no}/i).search_by(params.slice(:employee_name))
      else
        @total_census_employees_quantity = census_employees.count
        @census_employees = census_employees.search_by(params.slice(:employee_name)).to_a.first(20)
      end
    end

    def set_show_variables
      @current_plan_year = @employer_profile.published_plan_year
      @plan_years = @employer_profile.plan_years.order(id: :desc)

      if @current_plan_year.present?
        if @current_plan_year.eligible_to_enroll_count == 0
          @participation_minimum = 0
        else
          @participation_minimum = ((@current_plan_year.eligible_to_enroll_count * 2 / 3) + 0.999).to_i
        end
      end

      #broker view
      @broker_agency_accounts = @employer_profile.broker_agency_accounts

      #families view may require cache of broker agency profile id
      #families defined as employee_roles.each { |ee| ee.person.primary_family }
      if current_user.try(:has_broker_agency_staff_role?)
        session[:broker_agency_id] = current_user.person.broker_role.broker_agency_profile_id
      end
      @employees = []
      @employer_profile.employee_roles.each{|ee| @employees << ee}

    end

    def check_employer_staff_role
      if current_user.has_employer_staff_role?
        redirect_to employers_employer_profile_path(:id => current_user.person.employer_staff_roles.first.employer_profile_id)
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

    def check_admin_staff_role
      if current_user.has_hbx_staff_role? || current_user.has_broker_agency_staff_role?
      elsif current_user.has_employer_staff_role?
        redirect_to employers_employer_profile_path(:id => current_user.person.employer_staff_roles.first.employer_profile_id)
      else
        redirect_to new_employers_employer_profile_path
      end
    end

    def find_employer
      id_params = params.permit(:id, :employer_profile_id)
      id = id_params[:id] || id_params[:employer_profile_id]
      @employer_profile = EmployerProfile.find(id)
    end

    def employer_profile_params
      params.require(:organization).permit(
        :employer_profile_attributes => [ :entity_kind, :dba, :fein, :legal_name],
        :office_locations_attributes => [
          :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
          :phone_attributes => [:kind, :area_code, :number, :extension],
          :email_attributes => [:kind, :address]
        ]
      )
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

end
