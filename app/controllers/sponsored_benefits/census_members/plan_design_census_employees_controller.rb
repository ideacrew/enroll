require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployeesController < ApplicationController
    before_action :set_plan_design_census_employee, only: [:show, :edit, :update, :destroy]
    before_action :load_plan_design_benefit_application, only: [:index]
    before_action :load_plan_design_proposal, only: [:new, :bulk_employee_upload]

    def index
      @plan_design_census_employees = @benefit_application.plan_design_census_employees
    end

    def show
    end

    def new
      @census_employee = build_census_employee #SponsoredBenefits::Forms::PlanDesignCensusEmployee.new
      if params[:modal].present?
        respond_to do |format|
          format.js { render "upload_employees" }
        end
      end
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

    def bulk_employee_upload
      @census_employee_import = SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new({file: params.require(:file), proposal: @plan_design_proposal})
      
      respond_to do |format|
        if @census_employee_import.save
          format.html { redirect_to :back, :flash => { :success => "Roster uploaded successfully."} }
        else
          format.html { redirect_to :back, :flash => { :success => "Roster upload failed."} }
        end
      end
    end

    private

    def load_plan_design_proposal
      @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:proposal_id])
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
