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
    @hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments) || []

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

    end_date = TimeKeeper.date_of_record + future_days
    @qualified_date = (start_date <= qle_date && qle_date <= end_date) ? true : false
  end

  def inbox
  end
end
