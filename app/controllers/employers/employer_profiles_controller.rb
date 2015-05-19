class Employers::EmployerProfilesController < ApplicationController
  before_action :find_employer, only: [:show, :destroy]
  before_action :check_employer_staff_role, only: [:new, :welcome]

  def index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:page)[:page]
    page_no = page_string.blank? ? nil : page_string.to_i
    @organizations = Organization.search(@q).exists(employer_profile: true).page(page_no)
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
    @current_plan_year = @employer_profile.plan_years.last
    @benefit_groups = @current_plan_year.benefit_groups if @current_plan_year.present?
    @employee_families = @employer_profile.employee_families_sorted.page(params[:employee_families_page]).per(10)
  end

  def new
    @organization = build_employer_profile_params
  end

  def create
    if params[:organization].present?
      build_organization
      @organization.attributes = employer_profile_params
      if @organization.save
        flash[:notice] = 'Employer successfully created.'
        redirect_to employers_employer_profiles_path
      else
        render action: "new"
      end
    else
      found_employer = EmployerProfile.find_by_fein(params[:employer_profile][:fein])
      if found_employer.present?
        @employer_profile = found_employer
        @organization = @employer_profile.organization
        build_office_location
        respond_to do |format|
          format.js { render "edit" }
          format.html { render "edit" }
        end
      else
      end
    end
  end

  def update
    @organization = Organization.find(params[:id])
    @employer_profile = @organization.employer_profile
    current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
    current_user.person.employer_contact = @employer_profile
    if @organization.update_attributes(employer_profile_params) && current_user.save
      flash[:notice] = 'Employer successfully created.'
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      respond_to do |format|
        format.js { render "edit" }
        format.html { render "edit" }
      end
    end
  end

  private

    def check_employer_staff_role
      if current_user.has_employer_staff_role?
        redirect_to employers_employer_profile_path(current_user.person.get_employer_contact)
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
      office_location.build_email unless office_location.email.present?
      @organization
    end

end
