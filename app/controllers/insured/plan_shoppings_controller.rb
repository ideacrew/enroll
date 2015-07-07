class Insured::PlanShoppingsController < ApplicationController
  include Acapi::Notifiers

  def checkout
    plan = Plan.find(params.require(:plan_id))
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    hbx_enrollment.plan = plan
    benefit_group = hbx_enrollment.benefit_group
    reference_plan = benefit_group.reference_plan
    decorated_plan = PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, reference_plan)
    # notify("acapi.info.events.enrollment.submitted", hbx_enrollment.to_xml)

    if (hbx_enrollment.coverage_selected? or hbx_enrollment.select_coverage) and hbx_enrollment.save
      UserMailer.plan_shopping_completed(current_user, hbx_enrollment, decorated_plan).deliver_now
      redirect_to home_consumer_profiles_path
    else
      redirect_to :back
    end
  end

  def thankyou
    @person = current_user.person
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))
    @benefit_group = @enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    @family = @person.primary_family
    @enrollable = @family.is_eligible_to_enroll? && @benefit_group.plan_year.is_eligible_to_enroll?
    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    person = current_user.person
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    if hbx_enrollment.waive_coverage!
      redirect_to home_consumer_profiles_path
    else
      redirect_to :back
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

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
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
