require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployeesController < ApplicationController
    before_action :set_plan_design_census_employee, only: [:show, :edit, :update, :destroy]
    before_action :load_plan_design_benefit_application, only: [:index, :bulk_upload]
    before_action :load_plan_design_organization, only: [:new]

    def index
      @plan_design_census_employees = @benefit_application.plan_design_census_employees
    end

    def show
    end

    def new
      @census_employee = build_census_employee #SponsoredBenefits::Forms::PlanDesignCensusEmployee.new
    end

    def edit
    end

    def create
      @plan_design_census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new(census_members_plan_design_census_employee_params)

      if @plan_design_census_employee.save
        redirect_to @plan_design_census_employee, notice: 'Plan design census employee was successfully created.'
      else
        render :new
      end
    end

    def update
      if @plan_design_census_employee.update(census_members_plan_design_census_employee_params)
        redirect_to @plan_design_census_employee, notice: 'Plan design census employee was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @plan_design_census_employee.destroy
      redirect_to census_members_plan_design_census_employees_url, notice: 'Plan design census employee was successfully destroyed.'
    end

    def bulk_upload
      file = params.require(:file)
      @census_employee_import = SponsoredBenefits::Forms::CensusEmployeeImport.new({file:file, employer_profile: @employer_profile})
      
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

    private

    def load_plan_design_organization
      @plan_design_organization ||= SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:organization_id])
    end

    def load_plan_design_benefit_application
      @benefit_application = SponsoredBenefits::BenefitApplications::BenefitApplication.find(params.require(:benefit_application_id))
      @employer_profile = @benefit_application.employer_profile if @benefit_application.present?
    end
    
    def set_census_members_plan_design_census_employee
      @plan_design_census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find(params[:id])
    end

    def census_members_plan_design_census_employee_params
      params[:census_members_plan_design_census_employee]
    end


    def build_census_employee
      @census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new
      @census_employee.build_address
      @census_employee.build_email
      @census_employee
    end
  end
end
