class Employers::EmployerProfilesController < ApplicationController
  before_filter :find_employer, only: [:show, :destroy]

  def index
    @query = params[:name].blank? ? Organization : Organization.where(legal_name: /#{params[:name]}/i)
    @organizations = @query.exists(employer_profile: true).order_by([:legal_name]).page params[:page]
    @employer_profiles = @organizations.map {|o| o.employer_profile}
    #@employer_profiles = Kaminari.paginate_array(EmployerProfile.all.to_a).page params[:page]
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
    new_params = format_date_params(params)
    new_params.require(:organization).permit(
      :employer_profile_attributes => [ :entity_kind, :dba, :fein, :legal_name,
        :plan_years_attributes => [ :start_on, :end_on, :fte_count, :pte_count, :msp_count,
          :open_enrollment_start_on, :open_enrollment_end_on,
          :benefit_groups_attributes => [ :title, :reference_plan_id, :effective_on_offset,
            :premium_pct_as_int, :employer_max_amt_in_cents,
            :relationship_benefits_attributes => [
              :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
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

  def format_date_params(params)
    params[:organization][:employer_profile_attributes][:plan_years_attributes].each do |k, item|
      ["start_on", "end_on", "open_enrollment_start_on", "open_enrollment_end_on"].each do |key|
        unless item[key].include?("-")
          params[:organization][:employer_profile_attributes][:plan_years_attributes][k][key] = Date.strptime(item[key], '%m/%d/%Y').to_s(:db)
        end
      end
    end

    params
  rescue => e
    puts e
    params
  end
end
