class Employers::EmployerProfilesController < ApplicationController
  before_filter :find_employer, only: [:show, :destroy, :new_plan_year, :create_plan_year]

  def index
    @q = params[:q]
    @organizations = Organization.search(@q).exists(employer_profile: true).page params[:page]
    @employer_profiles = @organizations.map {|o| o.employer_profile}
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
    @organization = Organization.new
    @organization.build_employer_profile
    @organization.attributes = employer_profile_params
    if @organization.save
      flash[:notice] = 'Employer successfully created.'
      redirect_to employers_employer_profiles_path
    else
      render action: "new"
    end
  end

  def destroy
    @employer_profile.destroy

    respond_to do |format|
      format.html { redirect_to employers_employer_index_path, notice: "Employer successfully deleted." }
      format.json { head :no_content }
    end
  end

  def new_plan_year
    @plan_year = build_plan_year
  end

  def create_plan_year
    @employer_profile.plan_years.build(plan_year_params)
    if @employer_profile.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new_plan_year"
    end
  end

  private

  def find_employer
    id = params[:id] || params[:employer_profile_id]
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

  def plan_year_params
    new_params = format_date_params(params)
    new_params.require(:plan_year).permit(
      :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      :open_enrollment_start_on, :open_enrollment_end_on,
      :benefit_groups_attributes => [ :title, :reference_plan_id, :effective_on_offset,
        :premium_pct_as_int, :employer_max_amt_in_cents, :_destroy,
        :relationship_benefits_attributes => [
          :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
        ]
      ]
    )
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

  def build_plan_year
    plan_year = PlanYear.new
    benefit_groups = plan_year.benefit_groups.build
    relationship_benefits = benefit_groups.relationship_benefits.build
    plan_year
  end

  def format_date_params(params)
    ["start_on", "end_on", "open_enrollment_start_on", "open_enrollment_end_on"].each do |key|
      params["plan_year"][key] = Date.strptime(params["plan_year"][key], '%m/%d/%Y').to_s(:db)
    end

    params
  rescue => e
    puts e
    params
  end
end
