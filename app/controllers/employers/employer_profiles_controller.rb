class Employers::EmployerProfilesController < ApplicationController
  before_action :find_employer, only: [:show, :destroy]
  before_action :check_employer_role, only: [:new, :welcome]

  def index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:page)[:page]
    page_no = page_string.blank? ? nil : page_string.to_i
    @organizations = Organization.search(@q).exists(employer_profile: true).page page_no
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
  end

  def new
    @organization = build_employer_profile
  end

  def create
    if params[:organization].present?
      @organization = Organization.new
      @organization.build_employer_profile
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
        build_nested_models
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
    current_user.roles << "employer" unless current_user.roles.include?("employer")
    current_user.person.employer_contact = @employer_profile
    if @organization.update_attributes(employer_profile_params) && current_user.save
      flash[:notice] = 'Employer successfully created.'
      redirect_to employers_employer_profiles_path
    else
      render action: :new
    end
  end

  def destroy
    @employer_profile.destroy

    respond_to do |format|
      format.html { redirect_to employers_employer_index_path, notice: "Employer successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    def check_employer_role
      if current_user.has_employer_role?
        redirect_to employers_employer_profile_my_account_path(current_user.person.employer_contact)
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

    def employer_params
      params.require(:employer_profile).permit(:dba, :entity_kind, :fein, :legal_name)
    end

    def build_employer_profile
      organization = Organization.new
      organization.build_employer_profile
      office_location = organization.office_locations.build
      office_location.build_address
      office_location.build_phone
      office_location.build_email
      organization
    end

    def build_nested_models
      @organization.office_locations.build unless @organization.office_locations.present?
      office_location = @organization.office_locations.first
      office_location.build_address unless office_location.address.present?
      office_location.build_phone unless office_location.phone.present?
      office_location.build_email unless office_location.email.present?
      @organization
    end

end
