class Insured::PlanShoppingsController < ApplicationController
  include Acapi::Notifiers
  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show]
  before_action :set_kind_for_market_and_coverage, only: [:thankyou, :show]

  def checkout
    plan = Plan.find(params.require(:plan_id))
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    hbx_enrollment.update_current(plan_id: plan.id)
    hbx_enrollment.inactive_related_hbxs

    if hbx_enrollment.employee_role.present?
      #FIXME need send a params of market_kind
      benefit_group = hbx_enrollment.benefit_group
      reference_plan = benefit_group.reference_plan
      decorated_plan = PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, reference_plan)
    else
      decorated_plan = PlanCostDecorator.new(plan, hbx_enrollment, nil, nil)

    end
    # notify("acapi.info.events.enrollment.submitted", hbx_enrollment.to_xml)

    if hbx_enrollment.employee_role.present? && hbx_enrollment.employee_role.hired_on > TimeKeeper.date_of_record
      flash[:error] = "You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance"
      redirect_to family_account_path
    elsif hbx_enrollment.may_select_coverage?
      hbx_enrollment.update_current(aasm_state: "coverage_selected")
      hbx_enrollment.propogate_selection

      UserMailer.plan_shopping_completed(current_user, hbx_enrollment, decorated_plan).deliver_now if hbx_enrollment.try(:employee_roles).present?
      redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan])
    elsif hbx_enrollment.consumer_role_id.present?
      hbx_enrollment.update_current(aasm_state: "coverage_selected")
      hbx_enrollment.propogate_selection
      redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan])
    else
      redirect_to :back
    end
  end

  def receipt
    person = @person
    @enrollment = HbxEnrollment.find(params.require(:id))
    plan = @enrollment.plan
    if @enrollment.employee_role.present?
      benefit_group = @enrollment.benefit_group
      reference_plan = benefit_group.reference_plan
      @plan = PlanCostDecorator.new(plan, @enrollment, benefit_group, reference_plan)
    else
      @plan = PlanCostDecorator.new(plan, @enrollment, nil, nil)
    end
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    if @person.employee_roles.any?
      @employer_profile = @person.employee_roles.first.employer_profile
    end
  end

  def thankyou
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))

    if @market_kind == 'shop' and @coverage_kind == 'health'
      @benefit_group = @enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    else
      @plan = PlanCostDecorator.new(@plan, @enrollment, nil, nil)
    end
    @family = @person.primary_family
    #FIXME need to implement can_complete_shopping? for individual
    @enrollable = @market_kind == 'individual' ? true : @enrollment.can_complete_shopping?
    @waivable = @enrollment.can_complete_shopping?
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''

    if @person.employee_roles.any?
      @employer_profile = @person.employee_roles.first.employer_profile
    end

    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    person = @person
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    waiver_reason = params[:waiver_reason]

    if hbx_enrollment.may_waive_coverage? and waiver_reason.present? and hbx_enrollment.valid?
      hbx_enrollment.update_current(aasm_state: "inactive", waiver_reason: waiver_reason)
      hbx_enrollment.propogate_waiver
      redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment), notice: "Waive Successful"
    else
      redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment), alert: "Waive Failure"
    end
  end

  def print_waiver
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

  def terminate
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    if hbx_enrollment.may_terminate_coverage?
      hbx_enrollment.update_current(aasm_state: "coverage_terminated", terminated_on: TimeKeeper.date_of_record.end_of_month)
      hbx_enrollment.propogate_terminate

      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  def show
    hbx_enrollment_id = params.require(:id)

    Caches::MongoidCache.allocate(CarrierProfile)

    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    if @market_kind == 'shop' and @coverage_kind == 'health'
      @benefit_group = @hbx_enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plans = @benefit_group.elected_plans.entries.collect() do |plan|
        PlanCostDecorator.new(plan, @hbx_enrollment, @benefit_group, @reference_plan)
      end
    elsif @market_kind == 'individual' and @coverage_kind == 'health'
      elected_plans = Plan.where(market: "individual", active_year: TimeKeeper.date_of_record.year).select{|p| p.premium_tables.present?}
      #FIXME need benefit_package and reference_plan for individual
      @plans = elected_plans.collect() do |plan|
        PlanCostDecorator.new(plan, @hbx_enrollment, nil, nil)
      end
    elsif @coverage_kind == 'dental'
      elected_plans = Plan.where(coverage_kind: "dental", active_year: TimeKeeper.date_of_record.year).select{|p| p.premium_tables.present?}
      @plans = elected_plans.collect() do |plan|
        PlanCostDecorator.new(plan, @hbx_enrollment, nil, nil)
      end
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
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).map(&:to_f).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.is_a?(String) ? d.gsub(/[$,]/, '').to_i : 0}.max)

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
  end

  private
  def thousand_ceil(num)
    return 0 if num.blank?
    (num.fdiv 1000).ceil * 1000
  end

  def set_kind_for_market_and_coverage
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end
end
