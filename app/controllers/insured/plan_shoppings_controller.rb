class Insured::PlanShoppingsController < ApplicationController
  include Acapi::Notifiers

  def checkout
    @person = current_user.person
    @plan = Plan.find(params.require(:plan_id))
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
    @benefit_group = @hbx_enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @hbx_enrollment, @benefit_group, @reference_plan)
    UserMailer.plan_shopping_completed(current_user, @hbx_enrollment, @plan).deliver_now
    notify("acapi.info.events.enrollment.submitted", @hbx_enrollment.to_xml)

#    redirect_to thankyou_plan_shopping_path(id: @person, plan_id: params[:plan_id], organization_id: params[:organization_id])
    redirect_to home_consumer_profiles_path
  end

  def thankyou
    @person = current_user.person
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))
    @benefit_group = @enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    @family = @person.primary_family
    @enrollable = @family.is_eligible_to_enroll?
    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def show
    hbx_enrollment_id = params.require(:id)

    Caches::MongoidCache.allocate(CarrierProfile)

    @person = current_user.person
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    @benefit_group = @hbx_enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plans = @benefit_group.elected_plans.entries.collect() do |plan|
      PlanCostDecorator.new(plan, @hbx_enrollment, @benefit_group, @reference_plan)
    end
  end

  def find_person(id)
    begin
      Person.find(id)
    rescue
      nil
    end
  end

  def find_organization(id)
    begin
      Organization.find(id)
    rescue
      nil
    end
  end

  def find_benefit_group(person, organization)
    organization.employer_profile.latest_plan_year.benefit_groups.first
    # person.employee_roles.first.benefit_group
  end

  def new_hbx_enrollment(person, organization, benefit_group)
    HbxEnrollment.new_from(employer_profile: organization.employer_profile,
                           coverage_household: person.primary_family.households.first.coverage_households.first,
                           benefit_group: benefit_group)
  end
end
