class Consumer::EmployeeDependentsController < ApplicationController
  def index
    set_current_person
    @family = @person.primary_family
    emp_role_id = params.require(:employee_role_id)
    @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''
  end

  def new
    set_current_person
    @dependent = Forms::EmployeeDependent.new(:family_id => params.require(:family_id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    set_current_person
    @dependent = Forms::EmployeeDependent.new(params.require(:dependent))

    if @dependent.save
      @created = true
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      respond_to do |format|
        format.html { render 'new' }
        format.js { render 'new' }
      end
    end
  end

  def destroy
    set_current_person
    @family = @person.primary_family
    @dependent = Forms::EmployeeDependent.find(params.require(:id))
    @dependent.destroy!

    respond_to do |format|
      format.html { render 'index' }
      format.js { render 'destroyed' }
    end
  end

  def show
    set_current_person
    @family = @person.primary_family
    @dependent = Forms::EmployeeDependent.find(params.require(:id))

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    set_current_person
    @family = @person.primary_family
    @dependent = Forms::EmployeeDependent.find(params.require(:id))

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    set_current_person
    @family = @person.primary_family
    @dependent = Forms::EmployeeDependent.find(params.require(:id))

    if @dependent.update_attributes(params.require(:dependent))
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      respond_to do |format|
        format.html { render 'edit' }
        format.js { render 'edit' }
      end
    end
  end
end
