class Employers::CensusEmployeesController < ApplicationController
  before_action :find_employer
  before_action :find_census_employee, only: [:edit, :update, :show, :delink, :terminate, :rehire]
  before_action :check_plan_year, only: [:new]

  def new
    @census_employee = build_census_employee
  end

  def create
    @census_employee = CensusEmployee.new
    params.permit!
    @census_employee.attributes = params[:census_employee]
    if benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)
      @census_employee.benefit_group_assignments = new_benefit_group_assignment.to_a
      @census_employee.employer_profile = @employer_profile
      if @census_employee.save
        flash[:notice] = "Census Employee is successfully created."
        redirect_to employers_employer_profile_path(@employer_profile)
      else
        render action: "new"
      end
    else
      @census_employee.benefit_group_assignments.build if @census_employee.benefit_group_assignments.blank?
      flash[:error] = "Please select Benefit Group."
      render action: "new"
    end
  end

  def edit
    @census_employee.build_address unless @census_employee.address.present?
    @census_employee.benefit_group_assignments.build unless @census_employee.benefit_group_assignments.present?
  end

  def update
    params.permit!
    if benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)
      if @census_employee.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
        @census_employee.add_benefit_group_assignment(new_benefit_group_assignment)
      end

      if @census_employee.update_attributes(params[:census_employee])
        flash[:notice] = "Census Employee is successfully updated."
        redirect_to employers_employer_profile_path(@employer_profile)
      else
        render action: "edit"
      end
    else
      flash[:error] = "Please select Benefit Group."
      render action: "edit"
    end
  end

  def terminate
    termination_date = params.require(:termination_date)
    if termination_date.present?
      termination_date = DateTime.strptime(termination_date, '%m/%d/%Y').try(:to_date)
    else
      termination_date = ""
    end
    last_day_of_work = termination_date
    if termination_date.present?
      @census_employee.terminate_employment(last_day_of_work)
      @fa = @census_employee.save!
    end
    respond_to do |format|
      format.js {
        if termination_date.present? and @fa
          flash[:notice] = "Successfully terminated Census Employee."
          render text: true
        else
          render text: false
        end
      }
      format.all {
        flash[:notice] = "Successfully terminated Census Employee."
        redirect_to employers_employer_profile_path(@employer_profile)
      }
    end
  end

  def rehire
    rehiring_date = params["rehiring_date"]
    if rehiring_date.present?
      rehiring_date = DateTime.strptime(rehiring_date, '%m/%d/%Y').try(:to_date)
    else
      rehiring_date = ""
    end
    @rehiring_date = rehiring_date
    if @rehiring_date.present?
      new_census_employee = @census_employee.replicate_for_rehire
      if new_census_employee.present? # not an active family, then it is ready for rehire.#
        new_census_employee.hired_on = 1.day.ago.to_date
        new_census_employee.employer_profile = @employer_profile
        if new_census_employee.save
          flash[:notice] = "Successfully rehired Census Employee."
        else
          flash[:error] = "Error during rehire."
        end
      else # active family, dont replicate for rehire, just return error
        flash[:error] = "Census Employee is already active."
      end
    else
      flash[:error] = "Please enter rehiring date"
    end
  end

  def show
  end

  def delink
    @census_employee.delink_employee_role
    @census_employee.save!
    flash[:notice] = "Successfully delinked census employee."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  private

  def benefit_group_id
    params[:census_employee][:benefit_group_assignments_attributes]["0"][:benefit_group_id]
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_census_employee
    id = params[:id] || params[:census_employee_id]
    @census_employee = CensusEmployee.find(id)
  end

  def build_census_employee
    @census_employee = CensusEmployee.new
    @census_employee.build_address
    @census_employee.census_dependents.build
    @census_employee.benefit_group_assignments.build
    @census_employee
  end

  def check_plan_year
    if @employer_profile.plan_years.empty?
      flash[:notice] = "Please create a plan year before you create your first census employee."
      redirect_to new_employers_employer_profile_plan_year_path(@employer_profile)
    end
  end

end