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
    @hbx_enrollments = @family.latest_household.hbx_enrollments

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
    respond_to do |format|
      format.html
      format.js
    end
  end
end
