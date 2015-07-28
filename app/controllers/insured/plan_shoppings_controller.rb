class Insured::PlanShoppingsController < ApplicationController
  include Acapi::Notifiers
  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show]
  def checkout

    plan = Plan.find(params.require(:plan_id))
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    hbx_enrollment.plan = plan
    benefit_group = hbx_enrollment.benefit_group
    reference_plan = benefit_group.reference_plan
    decorated_plan = PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, reference_plan)
    # notify("acapi.info.events.enrollment.submitted", hbx_enrollment.to_xml)

    if hbx_enrollment.employee_role.hired_on > TimeKeeper.date_of_record
      flash[:error] = "You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance"
      redirect_to home_consumer_profiles_path
    elsif (hbx_enrollment.coverage_selected? or hbx_enrollment.select_coverage) and hbx_enrollment.save
      UserMailer.plan_shopping_completed(current_user, hbx_enrollment, decorated_plan).deliver_now
      redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan])
    else
      redirect_to :back
    end
  end

  def receipt
    person = @person
    @enrollment = HbxEnrollment.find(params.require(:id))
    plan = @enrollment.plan
    benefit_group = @enrollment.benefit_group
    reference_plan = benefit_group.reference_plan
    @plan = PlanCostDecorator.new(plan, @enrollment, benefit_group, reference_plan)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
  end

  def thankyou
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))
    @benefit_group = @enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    @family = @person.primary_family
    @enrollable = @enrollment.can_complete_shopping?
    @waivable = @enrollment.can_complete_shopping?
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''

    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    person = @person
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    waiver_reason = params.require(:waiver_reason)

    if (hbx_enrollment.shopping? or hbx_enrollment.coverage_selected?) and waiver_reason.present? and hbx_enrollment.valid?
      hbx_enrollment.waive_coverage
      hbx_enrollment.waiver_reason = waiver_reason
      hbx_enrollment.save
      flash[:notice] = "Waive Successful"
    else
      flash[:alert] = "Waive Failure"
    end
    redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment)
  end

  def print_waiver
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

  def terminate
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    if hbx_enrollment.coverage_selected? and hbx_enrollment.terminate_coverage and hbx_enrollment.save
      redirect_to home_consumer_profiles_path
    else
      redirect_to :back
    end
  end

  def show
    hbx_enrollment_id = params.require(:id)

    Caches::MongoidCache.allocate(CarrierProfile)

    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    @benefit_group = @hbx_enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plans = @benefit_group.elected_plans.entries.collect() do |plan|
      PlanCostDecorator.new(plan, @hbx_enrollment, @benefit_group, @reference_plan)
    end
    @waivable = @hbx_enrollment.can_complete_shopping?

    # for hsa-eligibility
    @plan_hsa_status = {}
    Products::Qhp.in(plan_id: @plans.map(&:id)).map {|qhp| @plan_hsa_status[qhp.plan_id.try(:to_s)] = qhp.hsa_eligibility}

    # for carrier search options
    if @benefit_group and @benefit_group.plan_option_kind == "metal_level"
      @carriers = @plans.map{|p| p.try(:carrier_profile).try(:legal_name) }.uniq
    else
      @carriers = Array.new(1, @plans.last.try(:carrier_profile).try(:legal_name))
    end
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.gsub(/[$,]/, '').to_i}.max)

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
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

  private
  def thousand_ceil(num)
    return 0 if num.blank?
    (num.fdiv 1000).ceil * 1000
  end
end
