class Employers::FamilyController < ApplicationController

  before_action :find_employer
  before_action :set_family_id, only: [:delink, :terminate, :rehire]
  before_action :find_family, only: [:destroy, :show, :edit, :update, :benefit_group, :assignment_benefit_group]
  before_action :check_plan_year, only: [:new]

  def new
    @family = build_family
  end

  def create
    @family = EmployerCensus::EmployeeFamily.new
    @family.attributes = census_family_params
    @employer_profile.employee_families << @family
    if @employer_profile.save
      flash[:notice] = "Employer Census Family is successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def edit
    @family.census_employee.build_address unless @family.census_employee.address.present?
    @family.benefit_group_assignments.build unless @family.benefit_group_assignments.present?
  end

  def update
    new_benefit_group_assignment = EmployerCensus::BenefitGroupAssignment.new
    new_benefit_group_assignment.attributes = census_family_params[:benefit_group_assignments_attributes]["0"]
    if @family.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
      @family.add_benefit_group_assignment(new_benefit_group_assignment)
    end

    if @family.update_attributes(census_family_params)
      flash[:notice] = "Employer Census Family is successfully updated."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "edit"
    end
  end

  def delink
    @family.delink_employee_role
    @family.save!
    flash[:notice] = "Successfully delinked family."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  def terminate
    termination_date = params["termination_date"]
    if termination_date.present?
      termination_date = DateTime.strptime(termination_date, '%m/%d/%Y').try(:to_date)
    else
      termination_date = ""
    end
    last_day_of_work = termination_date
    if termination_date.present?
      @family.terminate(last_day_of_work)
      @fa = @family.save!
    end
    respond_to do |format|
      format.js {
        if termination_date.present? and @fa
          flash[:notice] = "Successfully terminated family."
          render text: true
        else
          render text: false
        end
      }
      format.all {
        flash[:notice] = "Successfully terminated family."
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
      new_family = @family.replicate_for_rehire
      if new_family.present? # not an active family, then it is ready for rehire.#
        new_family.census_employee.hired_on = 1.day.ago.to_date
        @employer_profile.employee_families << new_family
        if @employer_profile.save
          flash[:notice] = "Successfully rehired family."
        else
          flash[:error] = "Error during rehire."
        end
      else # active family, dont replicate for rehire, just return error
        flash[:error] = "Family is already active."
      end
    else
      flash[:error] = "Please enter rehiring date"
    end
    #redirect_to employers_employer_profile_path(@employer_profile)
  end

  def show
  end

  def benefit_group
    @family.benefit_group_assignments.build unless @family.benefit_group_assignments.present?
  end

  def assignment_benefit_group
    benefit_group = @employer_profile.plan_years.first.benefit_groups.find_by(id: benefit_group_id)
    new_benefit_group_assignment = EmployerCensus::BenefitGroupAssignment.new_from_group_and_roster_family(benefit_group, @family)

    if @family.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
      @family.add_benefit_group_assignment(new_benefit_group_assignment)
    end

    if @family.save
      flash[:notice] = "Assignment benefit group is successfully."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "benefit_group"
    end
  end

  private
  def benefit_group_id
    census_family_params[:benefit_group_assignments_attributes]["0"][:benefit_group_id]
  end

  def census_family_params
    new_params = format_date_params(params)
    new_params.require(:employer_census_employee_family).permit(:id, :employer_profile_id,
      :census_employee_attributes => [
          :id, :first_name, :middle_name, :last_name, :name_sfx, :dob, :ssn, :gender, :hired_on, :terminated_on,
          :address_attributes => [ :id, :kind, :address_1, :address_2, :city, :state, :zip ],
        ],
      :census_dependents_attributes => [
          :id, :first_name, :last_name, :middle_name, :name_sfx, :dob, :gender, :employee_relationship, :_destroy
        ],
      :benefit_group_assignments_attributes => [
          :id, :start_on, :end_on, :is_active, :benefit_group_id
        ]
      )
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_family
    @family = EmployerCensus::EmployeeFamily.find(params["id"])
  end

  def set_family_id
    params[:id] = params[:family_id]
    find_family
  end

  def build_family
    family = EmployerCensus::EmployeeFamily.new
    family.build_census_employee
    family.build_census_employee.build_address
    family.benefit_group_assignments.build
    family
  end

  def check_plan_year
    if @employer_profile.plan_years.empty?
      flash[:notice] = "Please create a plan year before you create your first census family."
      redirect_to new_employers_employer_profile_plan_year_path(@employer_profile)
    end
  end

    def format_date_params(params)
      start_on = params[:employer_census_employee_family][:benefit_group_assignments_attributes]["0"][:start_on]
      params[:employer_census_employee_family][:benefit_group_assignments_attributes]["0"][:start_on] = Date.strptime(start_on, '%m/%d/%Y').to_s(:db)

      params
    rescue Exception => e
      puts e
      params
    end

end
