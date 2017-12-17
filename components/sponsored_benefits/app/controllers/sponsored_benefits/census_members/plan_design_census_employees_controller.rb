require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployeesController < ApplicationController
    before_action :set_census_members_plan_design_census_employee, only: [:show, :edit, :update, :destroy]

    # GET /census_members/plan_design_census_employees
    def index
      @census_members_plan_design_census_employees = CensusMembers::PlanDesignCensusEmployee.all
    end

    # GET /census_members/plan_design_census_employees/1
    def show
    end

    # GET /census_members/plan_design_census_employees/new
    def new
      @census_members_plan_design_census_employee = CensusMembers::PlanDesignCensusEmployee.new
    end

    # GET /census_members/plan_design_census_employees/1/edit
    def edit
    end

    # POST /census_members/plan_design_census_employees
    def create
      @census_members_plan_design_census_employee = CensusMembers::PlanDesignCensusEmployee.new(census_members_plan_design_census_employee_params)

      if @census_members_plan_design_census_employee.save
        redirect_to @census_members_plan_design_census_employee, notice: 'Plan design census employee was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /census_members/plan_design_census_employees/1
    def update
      if @census_members_plan_design_census_employee.update(census_members_plan_design_census_employee_params)
        redirect_to @census_members_plan_design_census_employee, notice: 'Plan design census employee was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /census_members/plan_design_census_employees/1
    def destroy
      @census_members_plan_design_census_employee.destroy
      redirect_to census_members_plan_design_census_employees_url, notice: 'Plan design census employee was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_census_members_plan_design_census_employee
        @census_members_plan_design_census_employee = CensusMembers::PlanDesignCensusEmployee.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def census_members_plan_design_census_employee_params
        params[:census_members_plan_design_census_employee]
      end
  end
end
