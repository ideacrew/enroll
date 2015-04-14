class Employers::EmployerProfilesController < ApplicationController
  before_filter :find_employer, only: [:show, :destroy]

  def index
    @employer_profiles = EmployerProfile.all.to_a
  end

  def my_account
  end

  def show
    @current_plan_year = @employer_profile.plan_years.last
    @benefit_groups = @current_plan_year.benefit_groups
  end

  def new
    @organization = build_employer_profile
  end

  def create
    @organization = Organization.new
    @organization.build_employer_profile
    @organization.attributes = employer_profile_params
    # Temp Hack for end_on and open_enrollment_end_on
    @organization.employer_profile.plan_years.first.end_on = 0.days.ago.end_of_year.to_date
    @organization.employer_profile.plan_years.first.open_enrollment_end_on = (0.days.ago.beginning_of_year.to_date - 2.months).end_of_month
    if @organization.save
      flash.notice = 'Employer successfully created.'
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

  private

  def find_employer
    @employer_profile = EmployerProfile.find(params[:id])
  end

  def employer_profile_params
    params.require(:organization).permit(
      :employer_profile_attributes => [ :entity_kind, :dba, :fein, :legal_name,
        :plan_years_attributes => [ :start_on, :end_on, :fte_count, :pte_count, :msp_count,
          :open_enrollment_start_on, :open_enrollment_end_on,
          :benefit_groups_attributes => [ :title, :reference_plan_id, :effective_on_offset,
            :premium_pct_as_int, :employer_max_amt_in_cents,
            :relationship_benefits_attributes => [
              :relationship, :premium_pct, :employer_max_amt, :offered
            ]
          ]
        ]
      ],
      :office_locations_attributes => [
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
        :phone_attributes => [:kind, :area_code, :number, :extension],
        :email_attributes => [:kind, :address]
      ]
    )
  end

  def build_employer_profile
    organization = Organization.new
    organization.build_employer_profile
    plan_year = organization.employer_profile.plan_years.build
    benefit_groups = plan_year.benefit_groups.build
    relationship_benefits = benefit_groups.relationship_benefits.build
    office_location = organization.office_locations.build
    office_location.build_address
    office_location.build_phone
    office_location.build_email
    organization
  end
end
