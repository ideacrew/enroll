class ConsumerProfilesController < ApplicationController
  def home
    @person = current_user.person
    @family = @person.primary_family
    @family_members = @family.active_family_members if @family.present?
    @employee_roles = @person.employee_roles
    @employer_profile = @employee_roles.first.employer_profile if @employee_roles.any?
    @current_plan_year = @employer_profile.latest_plan_year if @employer_profile.present?
    @benefit_groups = @current_plan_year.benefit_groups if @current_plan_year.present?
    @benefit_group = @current_plan_year.benefit_groups.first if @current_plan_year.present?
    @qualifying_life_events = QualifyingLifeEventKind.all
    @hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active || []

    @employee_role = @employee_roles.first

    respond_to do |format|
      format.html
      format.js
    end
  end

  def build_nested_models

    ["home","mobile","work","fax"].each do |kind|
       @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
    end

    ["home","work"].each do |kind|
       @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def plans
    @person = current_user.person
    @employee_roles = @person.employee_roles
    @employer_profile = @employee_roles.first.employer_profile if @employee_roles.any?
    @current_plan_year = @employer_profile.latest_plan_year if @employer_profile.present?
    @benefit_group = @current_plan_year.benefit_groups.first if @current_plan_year.present?
    @plan = @benefit_group.reference_plan
    @qhp = Products::Qhp.where(standard_component_id: @plan.hios_id[0..13]).to_a.first
    @qhp_benefits = @qhp.qhp_benefits
    respond_to do |format|
      format.html
      format.js
    end
  end

  def personal
    @person = current_user.person
    @family = @person.primary_family
    @family_members = @family.active_family_members if @family.present?
    respond_to do |format|
      format.html
      format.js
    end
  end

  def family
    @person = current_user.person
    @family = @person.primary_family
    @family_members = @family.active_family_members if @family.present?

    @qualifying_life_events = QualifyingLifeEventKind.all
    @employee_role = @person.employee_roles.first

    respond_to do |format|
      format.html
      format.js
    end
  end

  def check_qle_date
    qle_date = Date.strptime(params[:date_val], "%m/%d/%Y")
    start_date = Date.strptime('01/10/2013', "%m/%d/%Y")
    future_days = 30.days

    if ["I've had a baby", "Death"].include? params[:qle_type]
      future_days = 0.days

    end

    end_date = Date.today + future_days

    @qualified_date = (start_date <= qle_date && qle_date <= end_date) ? true : false
  end

  def inbox
  end

  def purchase
    @person = current_user.person
    @family = @person.primary_family
    @enrollment = @family.try(:latest_household).try(:hbx_enrollments).active.last

    if @enrollment.present?
      plan = @enrollment.try(:plan)
      @benefit_group = @enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(plan, @enrollment, @benefit_group, @reference_plan)
      @enrollable = @family.is_eligible_to_enroll? && @benefit_group.plan_year.is_eligible_to_enroll?
    else
      redirect_to :back
    end
  end
end
