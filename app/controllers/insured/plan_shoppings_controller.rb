class Insured::PlanShoppingsController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include Aptc
  include Config::AcaHelper
  include L10nHelper

  before_action :find_hbx_enrollment
  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show, :plans, :checkout, :terminate, :plan_selection_callback]
  before_action :set_kind_for_market_and_coverage, only: [:thankyou, :show, :plans, :checkout, :receipt, :set_elected_aptc, :plan_selection_callback]
  before_action :validate_rating_address, only: [:show]
  before_action :check_enrollment_state, only: [:show, :thankyou]
  before_action :set_cache_headers, only: [:show, :thankyou]

  def checkout
    (redirect_back(fallback_location: root_path) and return) unless agreed_to_thankyou_ivl_page_terms

    authorize @hbx_enrollment, :checkout?
    @enrollment = @hbx_enrollment

    plan_selection = PlanSelection.for_enrollment_id_and_plan_id(params.require(:id), params.require(:plan_id))

    if plan_selection.employee_is_shopping_before_hire?
      session.delete(:pre_hbx_enrollment_id)
      flash[:error] = "You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance"
      redirect_to family_account_path
      return
    end

    qle = (plan_selection.hbx_enrollment.enrollment_kind == "special_enrollment")

    if !plan_selection.hbx_enrollment.can_select_coverage?(qle: qle)
      if plan_selection.hbx_enrollment.errors.present?
        flash[:error] = plan_selection.hbx_enrollment.errors.full_messages
      end
        redirect_back(fallback_location: :back)
      return
    end

    get_aptc_info_from_session(plan_selection.hbx_enrollment)
    plan_selection.apply_aptc_if_needed(@elected_aptc, @max_aptc) if can_apply_aptc?(plan_selection.plan)
    previous_enrollment_id = session[:pre_hbx_enrollment_id]

    plan_selection.verify_and_set_member_coverage_start_dates
    plan_selection.select_plan_and_deactivate_other_enrollments(previous_enrollment_id,params[:market_kind])

    session.delete(:pre_hbx_enrollment_id)
    redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan], enrollment_kind: params[:enrollment_kind])
  end

  def receipt
    authorize @hbx_enrollment, :receipt?
    @enrollment = @hbx_enrollment
    @plan = @enrollment.product

    if @enrollment.is_shop?
      @employer_profile = @enrollment.employer_profile
    else
      applied_aptc = @enrollment.applied_aptc_amount if @enrollment.applied_aptc_amount > 0
      @market_kind = "individual"
    end
    if @enrollment.is_shop?
      @member_group = HbxEnrollmentSponsoredCostCalculator.new(@enrollment).groups_for_products([@plan]).first
    else
      @plan = @enrollment.build_plan_premium(qhp_plan: @plan, apply_aptc: applied_aptc.present?, elected_aptc: applied_aptc)
    end

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    # employee_mid_year_plan_change(@person, @change_plan)
    # @enrollment.ee_plan_selection_confirmation_sep_new_hire #mirror notice
    # @enrollment.mid_year_plan_change_notice #mirror notice
    send_receipt_emails if @person.emails.first
  end

  def thankyou
    authorize @hbx_enrollment, :thankyou?

    @enrollment = @hbx_enrollment
    set_elected_aptc_by_params(params[:elected_aptc]) if params[:elected_aptc].present?
    set_consumer_bookmark_url(family_account_path)
    set_admin_bookmark_url(family_account_path)
    @plan = BenefitMarkets::Products::Product.find(params[:plan_id])
    @enrollment.set_special_enrollment_period

    if @enrollment.is_shop?
      @employer_profile = @enrollment.employer_profile
    else
      get_aptc_info_from_session(@enrollment)
    end

    # TODO Fix this stub
    if @enrollment.is_shop?
      @member_group = HbxEnrollmentSponsoredCostCalculator.new(@enrollment).groups_for_products([@plan]).first
      @enrollment.verify_and_reset_osse_subsidy_amount(@member_group)
    else
      @enrollment.reset_dates_on_previously_covered_members(@plan)
      set_aptcs_for_continuous_coverage
      revise_applied_aptc_for_osse
      @plan = @enrollment.build_plan_premium(qhp_plan: @plan, apply_aptc: can_apply_aptc?(@plan), elected_aptc: @elected_aptc)
      @enrollment.update(eligible_child_care_subsidy: @plan.total_childcare_subsidy_amount)
    end

    @family = @person.primary_family

    #FIXME need to implement can_complete_shopping? for individual
    @enrollable = @market_kind == 'individual' ? true : @enrollment.can_complete_shopping?(qle: @enrollment.is_special_enrollment?)
    @waivable = @enrollment.can_complete_shopping?
    @change_plan =
      if params[:change_plan].present?
        params[:change_plan]
      elsif @enrollment.is_special_enrollment?
        "change_plan"
      end
    @enrollment_kind =
      if params[:enrollment_kind].present?
        params[:enrollment_kind]
      elsif @enrollment.is_special_enrollment?
        "sep"
      else
        ""
      end
    dependents_with_existing_coverage(@enrollment) if @market_kind == 'individual' && EnrollRegistry.feature_enabled?(:existing_coverage_warning)
    #flash.now[:error] = qualify_qle_notice unless @enrollment.can_select_coverage?(qle: @enrollment.is_special_enrollment?)

    if EnrollRegistry.feature_enabled?(:enrollment_product_date_match) || (@plan.present? && @plan.application_period.cover?(@enrollment.effective_on)) || @enrollment.is_shop?
      respond_to do |format|
        format.html { render 'thankyou.html.erb' }
      end
    else
      flash[:error] = "Your selected plan is unavailable for #{@enrollment.effective_on.year}. Please select another plan"
      redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: @enrollment.id)
    end
  end

  # Waives against an existing enrollment
  def waive
    authorize @hbx_enrollment, :waive?
    hbx_enrollment = @hbx_enrollment
    waiver_success = false

    begin
      if hbx_enrollment.shopping?
        @waiver_enrollment = hbx_enrollment
      else
        @waiver_enrollment = hbx_enrollment.construct_waiver_enrollment(params[:waiver_reason]) unless hbx_enrollment.waiver_enrollment_present?
      end

      if @waiver_enrollment.present?
        if @waiver_enrollment.may_waive_coverage?
          @waiver_enrollment.waiver_reason = params[:waiver_reason]
          @waiver_enrollment.waive_enrollment
        end

        waiver_success = true if @waiver_enrollment.inactive?
      end

      if waiver_success
        redirect_to print_waiver_insured_plan_shopping_path(@waiver_enrollment), notice: "Waive Coverage Successful"
      else
        redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
      end
    rescue StandardError => e
      log(e.message, :severity => 'error')
      redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
    end
  end

  def print_waiver
    authorize @hbx_enrollment, :print_waiver?
  end

  def terminate
    authorize @hbx_enrollment, :terminate?

    coverage_end_date = params[:terminate_date].present? ? Date.strptime(params[:terminate_date], "%m/%d/%Y") : @person.primary_family.terminate_date_for_shop_by_enrollment(@hbx_enrollment)
    # Exception is thrown buried in this method
    @hbx_enrollment.terminate_enrollment(coverage_end_date, params[:terminate_reason])
    if (@hbx_enrollment.coverage_terminated? || @hbx_enrollment.coverage_termination_pending? || @hbx_enrollment.coverage_canceled?) && @hbx_enrollment.waiver_enrollment_present?
      @hbx_enrollment.update_renewal_coverage
      household = @person.primary_family.active_household
      household.reload
      waiver_enrollment = household.hbx_enrollments.where(predecessor_enrollment_id: @hbx_enrollment.id).first
      redirect_to print_waiver_insured_plan_shopping_path(waiver_enrollment), notice: "Waive Coverage Successful"
    else
      # This is the unsuccessful stuff the errors probably will have to go here.
      alert_message = @hbx_enrollment.construct_waiver_enrollment&.errors&.messages&.values&.flatten&.join(", ")
      redirect_back(
        fallback_location: :root_path,
        alert: alert_message
      )
    end
  end

  def show
    authorize @hbx_enrollment, :show?

    hbx_enrollment_id = params.require(:id)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    case params[:market_kind]
    when 'shop', 'fehb'
      show_shop(hbx_enrollment_id)
    when 'individual', 'coverall'
      show_ivl(hbx_enrollment_id)
    end
  end

  def plan_selection_callback
    authorize @hbx_enrollment, :plan_selection_callback?

    year = params[:year]
    hios_id = params[:hios_id]
    @enrollment = @hbx_enrollment
    market_kind = @enrollment.fehb_profile ? 'fehb' : @enrollment.kind
    selected_plan = if @enrollment.fehb_profile
                      BenefitMarkets::Products::Product.where(:hios_id => hios_id, :"application_period.min" => Date.new(year.to_i, 1, 1), benefit_market_kind: :fehb).first
                    else
                      BenefitMarkets::Products::Product.where(:hios_id => hios_id, :"application_period.min" => Date.new(year.to_i, 1, 1)).first
                    end
    if selected_plan.present?
      redirect_to thankyou_insured_plan_shopping_path({plan_id: selected_plan.id.to_s, id: params[:id],coverage_kind: params[:coverage_kind], market_kind: market_kind, change_plan: params[:change_plan]})
    else
      redirect_to insured_plan_shopping_path(request.params), :flash => "No plan selected"
    end
  end

  def set_elected_aptc
    authorize @hbx_enrollment, :set_elected_aptc?

    session[:elected_aptc] = params[:elected_aptc].to_f
    plan_comparision_obj = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment)
    plan_comparision_obj.elected_aptc = session[:elected_aptc]
    checkbook_url = plan_comparision_obj.generate_url
    respond_to do |format|
      format.json { render json: {message: 'ok',checkbook_url: checkbook_url } }
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def plans
    authorize @hbx_enrollment, :plans?

    set_consumer_bookmark_url(family_account_path)
    set_admin_bookmark_url(family_account_path)
    set_plans_by(hbx_enrollment_id: params.require(:id))

    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      aptc_grants(@hbx_enrollment.family, @hbx_enrollment.effective_on.year) if @person.present?
    else
      begin
        @tax_household = @person.primary_family.latest_household.latest_active_tax_household_with_year(@hbx_enrollment.effective_on.year)
      rescue StandardError => e
        log("#{e.message}; person_id: #{@person.id}")
      end
    end
    if @tax_household.present? || @aptc_grants.present?
      entity = @tax_household || @aptc_grants
      @csr_available = is_eligibility_determined_and_not_csr_0?(entity)
      if @csr_available
        sort_for_csr(@plans)
      else
        sort_by_standard_plans(@plans)
        @plans = @plans.partition{ |a| @enrolled_hbx_enrollment_plan_ids.include?(a[:id]) }.flatten
      end
    else
      sort_by_standard_plans(@plans)
      @plans = @plans.partition{ |a| @enrolled_hbx_enrollment_plan_ids.include?(a[:id]) }.flatten
    end
    @plan_hsa_status = Products::Qhp.plan_hsa_status_map(@plans)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  private


  # Determines if the user has agreed to the terms on the individual market thank you page.
  # The user has agreed if the 'thankyou_page_agreement_terms' parameter is set to 'agreed'.
  # This check is only performed for enrollments of individual market kinds.
  #
  # @return [Boolean] Returns true if the user has agreed to the terms or the enrollment is not of individual market kind, false otherwise.
  # @note This method sets a flash error message if the user has not agreed to the terms.
  def agreed_to_thankyou_ivl_page_terms
    return true unless HbxEnrollment::IVL_KINDS.include?(@hbx_enrollment.kind)
    return true if params['thankyou_page_agreement_terms'] == 'agreed'

    flash[:error] = l10n('insured.plan_shopping.thankyou.agreement_terms_conditions')
    false
  end

  # Sets the HTTP response headers to prevent caching.
  #
  # This method sets the `Cache-Control` and `Pragma` headers in the HTTP response
  # to instruct browsers and caches to always request a fresh copy of the response
  # from the server, rather than serving a cached version.
  #
  # The `Cache-Control` header is set with the following directives:
  #
  # - `no-cache`: The response may be stored by caches, but they must first validate
  #   the response with the server before using it.
  # - `no-store`: The response must not be stored in any cache, including browser caches.
  # - `private`: The response should only be cached by a single user's browser, not by
  #   shared caches.
  # - `must-revalidate`: Caches must verify the status of the response with the server
  #   before using a cached copy.
  #
  # @return [void]
  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, private, must-revalidate"
    response.headers["Pragma"] = "no-cache"
  end

  # check the enrollment state of the current HBX enrollment.
  # This method is used to prevent users from clicking the browser's back button
  # and resubmitting an enrollment that has already been submitted.
  #
  # If the enrollment is in the 'shopping' state, no action is taken.
  # Otherwise, a notice flash message is displayed, and the user is redirected
  # to the family account page.
  #
  # @return [void]
  def check_enrollment_state
    return if @hbx_enrollment.shopping?

    redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan], enrollment_kind: params[:enrollment_kind])
  end

  def show_ivl(hbx_enrollment_id)
    set_consumer_bookmark_url(family_account_path) if params[:market_kind] == 'individual'
    set_admin_bookmark_url(family_account_path) if params[:market_kind] == 'individual'
    set_resident_bookmark_url(family_account_path) if params[:market_kind] == 'coverall'
    @hbx_enrollment.reset_member_coverage_start_dates # Fixes coverage start date and aptc slider calculation issues related to browser navigation and page reload
    set_plans_by(hbx_enrollment_id: hbx_enrollment_id)
    collect_shopping_filters

    generate_eligibility_data
    generate_checkbook_service if params[:market_kind] == 'individual'
    @carriers = @carrier_names_map.values
    @waivable = @hbx_enrollment.try(:can_complete_shopping?)
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).map(&:to_f).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.is_a?(String) ? d.gsub(/[$,]/, '').to_i : 0}.max)
  end

  def show_shop(hbx_enrollment_id)
    set_employee_bookmark_url(family_account_path) if params[:market_kind] == 'shop' || params[:market_kind] == 'fehb'
    @hbx_enrollment.update_osse_childcare_subsidy
    sponsored_cost_calculator = HbxEnrollmentSponsoredCostCalculator.new(@hbx_enrollment)
    products = @hbx_enrollment.sponsored_benefit.products(@hbx_enrollment.sponsored_benefit.rate_schedule_date)
    product_ids = products.map(&:id)
    # Fetch latest data from product that might not be updated with product_package.products
    products = BenefitMarkets::Products::Product.where(:id.in => product_ids)
    @issuer_profiles = []
    @issuer_profile_ids = products.map(&:issuer_profile_id).uniq
    ip_lookup_table = {}
    ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ipo|
      if @issuer_profile_ids.include?(ipo.issuer_profile.id)
        @issuer_profiles << ipo.issuer_profile
        ip_lookup_table[ipo.issuer_profile.id] = ipo.issuer_profile
      end
    end
    ::Caches::CustomCache.allocate(::BenefitSponsors::Organizations::Organization, :plan_shopping, ip_lookup_table)
    @enrolled_hbx_enrollment_plan_ids = @hbx_enrollment.family.current_enrolled_or_termed_coverages(@hbx_enrollment, true).collect(&:product_id)

    @member_groups = sort_member_groups(sponsored_cost_calculator.groups_for_products(products))
    @products = @member_groups.map(&:group_enrollment).map(&:product)
    extract_from_shop_products

    if checkbook_integration_enabled?
      is_congress_employee = @hbx_enrollment.fehb_profile ? true : false
      @plan_comparison_checkbook_url = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment, is_congress_employee).generate_url
    end

    @networks = @products.map(&:network).uniq.compact if offers_nationwide_plans?
    @carrier_names = @issuer_profiles.map(&:legal_name)
    @use_family_deductable = (@hbx_enrollment.hbx_enrollment_members.count > 1)
    @waivable = @hbx_enrollment.can_waive_enrollment?
    @sponsored_benefit = @hbx_enrollment.sponsored_benefit
    render "show"
    ::Caches::CustomCache.release(::BenefitSponsors::Organizations::Organization, :plan_shopping)
  end

  def fix_member_dates(enrollment, plan)
    return if enrollment.parent_enrollment.present? && plan.id == enrollment.parent_enrollment.product_id

    @enrollment.hbx_enrollment_members.each do |member|
      member.coverage_start_on = enrollment.effective_on
    end
  end

  def employee_mid_year_plan_change(person,change_plan)
    ce = person.active_employee_roles.first.census_employee
    trigger_notice_observer(ce.employer_profile, @enrollment, 'employee_mid_year_plan_change_notice_to_employer') if change_plan.present? || ce.new_hire_enrollment_period.present?
  rescue StandardError => e
    log("#{e.message}; person_id: #{person.id}")
  end

  def generate_eligibility_data
    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      @grants = aptc_grants(@person.primary_family, @hbx_enrollment.effective_on.year)
      @max_aptc = ::Operations::PremiumCredits::FindAptc.new.call({hbx_enrollment: @hbx_enrollment, effective_on: @hbx_enrollment.effective_on}).value!
      @hbx_enrollment.update_attributes(aggregate_aptc_amount: @max_aptc)
      session[:max_aptc] = @max_aptc
      default_aptc_percentage = EnrollRegistry[:enroll_app].setting(:default_aptc_percentage).item
      @elected_aptc = session[:elected_aptc] = (@max_aptc * default_aptc_percentage) / 100
      @tax_household = @grants
    else
      shopping_tax_household = get_shopping_tax_household_from_person(@person, @hbx_enrollment.effective_on.year)

      if shopping_tax_household.present? && @hbx_enrollment.coverage_kind == 'health' && @hbx_enrollment.kind == 'individual'
        @tax_household = shopping_tax_household
        @max_aptc = @tax_household.total_aptc_available_amount_for_enrollment(@hbx_enrollment, @hbx_enrollment.effective_on)
        @hbx_enrollment.update_attributes(aggregate_aptc_amount: @max_aptc)
        session[:max_aptc] = @max_aptc
        default_aptc_percentage = EnrollRegistry[:enroll_app].setting(:default_aptc_percentage).item
        @elected_aptc = session[:elected_aptc] = (@max_aptc * default_aptc_percentage) / 100
      else
        session[:max_aptc] = 0
        session[:elected_aptc] = 0
      end
    end
  end

  def generate_checkbook_service
    plan_comparision_obj = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment)
    plan_comparision_obj.elected_aptc = session[:elected_aptc]
    @dc_individual_checkbook_url = plan_comparision_obj.generate_url
  end

  def extract_from_shop_products
    if ['health', 'dental'].include?(@hbx_enrollment.coverage_kind)
      @metal_levels = @products.map(&:metal_level).uniq
      @plan_types = @products.map(&:product_type).uniq
    else
      @plan_types = []
      @metal_levels = []
    end
  end

  def set_aptcs_for_continuous_coverage
    return unless EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
    return unless @enrollment.continuous_coverage?
    return if @max_aptc.zero?

    percentage = @elected_aptc / @max_aptc
    @max_aptc = ::Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: @enrollment, effective_on: @enrollment.effective_on }).value!
    @elected_aptc = percentage * @max_aptc
    session[:elected_aptc] = @elected_aptc.to_f
    session[:max_aptc] = @max_aptc.to_f
  end

  def revise_applied_aptc_for_osse
    return unless osse_aptc_minimum_enabled? && @enrollment.ivl_osse_eligible?
    return if @max_aptc.zero?

    applied_percentage = (@elected_aptc / @max_aptc).to_f
    minimum_applied_aptc_for_osse = EnrollRegistry[:aca_individual_assistance_benefits].setting(:minimum_applied_aptc_percentage_for_osse).item.to_f

    return unless applied_percentage < minimum_applied_aptc_for_osse

    @elected_aptc = minimum_applied_aptc_for_osse * @max_aptc
    session[:elected_aptc] = @elected_aptc.to_f
  end

  def osse_aptc_minimum_enabled?
    EnrollRegistry.feature_enabled?(:aca_individual_osse_aptc_minimum)
  end

  def dependents_with_existing_coverage(enrollment)
    existing_coverages = ::Operations::FetchExistingCoverage.new.call({enrollment_id: enrollment.id})
    existing_enrollments = existing_coverages.success? ? existing_coverages.value! : []
    primary_subscriber = enrollment.subscriber
    existing_dependent_enrollments = existing_enrollments.reject{ |enr| enr.subscriber.applicant_id == primary_subscriber.applicant_id }
    return if existing_dependent_enrollments.nil? || existing_dependent_enrollments.count == 0
    applicant_ids = existing_dependent_enrollments.map(&:hbx_enrollment_members).flatten.map(&:hbx_id).uniq
    @dependent_members = enrollment.hbx_enrollment_members.select{|member| applicant_ids.include?(member.hbx_id)}
  end

  def find_hbx_enrollment
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

  def collect_shopping_filters
    if params[:coverage_kind] == 'health'
      @metal_levels = %w[bronze catastrophic silver gold platinum]
      @plan_types = %w[hmo pos ppo]
    else
      @metal_levels = %w[high low]
      @plan_types = %w[ppo hmo epo]
    end
    @networks = ::BenefitMarkets::Products::Product.network_labels
  end

  # no dental as of now
  def sort_member_groups(products)
    products.select { |prod| prod.group_enrollment.product.id.to_s == @enrolled_hbx_enrollment_plan_ids.first.to_s } + products.select { |prod| prod.group_enrollment.product.id.to_s != @enrolled_hbx_enrollment_plan_ids.first.to_s }.sort_by { |mg| (mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total) }
  end

  def sort_by_standard_plans(plans)
    standard_plans, other_plans = plans.partition{|p| p.is_standard_plan? == true}
    standard_plans = standard_plans.sort_by(&:total_employee_cost).sort{|a,b| b.csr_variant_id <=> a.csr_variant_id}
    other_plans = other_plans.sort_by(&:total_employee_cost).sort{|a,b| b.csr_variant_id <=> a.csr_variant_id}
    @plans = standard_plans + other_plans
  end

  def sort_for_csr(plans)
    silver_plans, non_silver_plans = plans.partition{|a| a.metal_level == "silver"}
    standard_plans, non_standard_plans = silver_plans.partition{|a| a.is_standard_plan == true}
    @plans = standard_plans + non_standard_plans + non_silver_plans
  end

  def is_eligibility_determined_and_not_csr_0?(entity)
    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      enrolled_family_member_ids = @hbx_enrollment.hbx_enrollment_members.map(&:applicant_id)
      csr_op = ::Operations::PremiumCredits::FindCsrValue.new.call({
                                                                     family: @hbx_enrollment.family,
                                                                     year: @hbx_enrollment.effective_on.year,
                                                                     family_member_ids: enrolled_family_member_ids
                                                                   })

      return false unless csr_op.success?

      valid_csr_eligibility_kind = csr_op.value!
    else
      valid_csr_eligibility_kind = entity.valid_csr_kind(@hbx_enrollment)
    end

    (EligibilityDetermination::CSR_KINDS.include? valid_csr_eligibility_kind.to_s) && (valid_csr_eligibility_kind.to_s != 'csr_0')
  end

  def send_receipt_emails
    email = @person.work_email_or_best
    UserMailer.generic_consumer_welcome(@person.first_name, @person.hbx_id, email).deliver_now
    is_confirmation_email_enabled = if @enrollment.is_shop?
                                      EnrollRegistry.feature_enabled?(:send_shop_secure_purchase_confirmation_email)
                                    else
                                      EnrollRegistry.feature_enabled?(:send_ivl_secure_purchase_confirmation_email)
                                    end
    return unless is_confirmation_email_enabled

    body = render_to_string 'user_mailer/secure_purchase_confirmation.html.erb', layout: false
    from_provider = HbxProfile.current_hbx
    message_params = {
      sender_id: from_provider.try(:id),
      parent_message_id: @person.id,
      from: from_provider.try(:legal_name),
      to: @person.full_name,
      body: body,
      subject: 'Your Enrollment Confirmation'
    }
    create_secure_message(message_params, @person, :inbox)
  end

  def set_plans_by(hbx_enrollment_id:)
    Caches::MongoidCache.allocate(CarrierProfile)

    @enrolled_hbx_enrollment_plan_ids = @hbx_enrollment.family.current_enrolled_or_termed_products_by_subscriber(@hbx_enrollment).map(&:id)

    if @hbx_enrollment.blank?
      @plans = []
    else
      if @hbx_enrollment.is_shop?
        @benefit_group = @hbx_enrollment.benefit_group
        @plans = @benefit_group.decorated_elected_plans(@hbx_enrollment, @coverage_kind)
      else
        @plans = @hbx_enrollment.decorated_elected_plans(@coverage_kind, @market_kind)
      end

      build_same_plan_premiums
    end

    @plans = @plans.select { |a| a.premium_tables.present? }

    # for carrier search options
    carrier_profile_ids = @plans.map(&:issuer_profile_id).map(&:to_s).uniq
    @carrier_names_map = BenefitSponsors::Organizations::Organization.valid_issuer_names_filters.select{|k, _v| carrier_profile_ids.include?(k)}
  end

  def enrolled_plans_by_hios_id_and_active_year
    family = @hbx_enrollment.family
    if @hbx_enrollment.is_shop?
      @enrolled_hbx_enrollment_plans = family.current_enrolled_or_termed_coverages(@hbx_enrollment, true).collect(&:product_id)
      (@plans.collect(&:id) & @enrolled_hbx_enrollment_plan_ids)
    else
      @enrolled_hbx_enrollment_plans = family.current_enrolled_or_termed_products_by_subscriber(@hbx_enrollment)
      @enrolled_hbx_enrollment_plans = family.current_enrolled_or_termed_products(@hbx_enrollment) if @enrolled_hbx_enrollment_plans.empty?
      (@plans.select{|plan| @enrolled_hbx_enrollment_plans.select {|existing_plan| plan.is_same_plan_by_hios_id_and_active_year?(existing_plan) }.present? }).collect(&:id)
    end
  end

  def build_same_plan_premiums
    enrolled_plans = enrolled_plans_by_hios_id_and_active_year

    if enrolled_plans.present?
      enrolled_plans = enrolled_plans.collect{|p| BenefitMarkets::Products::Product.find(p)}

      plan_selection = PlanSelection.new(@hbx_enrollment, @hbx_enrollment.product || enrolled_plans.first)
      same_plan_enrollment = plan_selection.same_plan_enrollment

      if @hbx_enrollment.is_shop?
        ref_plan = (@hbx_enrollment.coverage_kind == "health" ? @benefit_group.reference_plan : @benefit_group.dental_reference_plan)

        @enrolled_plans = enrolled_plans.collect{|plan|
          @benefit_group.decorated_plan(plan, same_plan_enrollment, ref_plan)
        }
      else
        @enrolled_plans = same_plan_enrollment.calculate_costs_for_plans(enrolled_plans)
      end

      @enrolled_plans.each do |enrolled_plan|
        case  @hbx_enrollment.is_shop?
        when false
          if plan_index = @plans.index{|e| e.is_same_plan_by_hios_id_and_active_year?(enrolled_plan) }
            @plans[plan_index] = enrolled_plan
          end
        else
          if plan_index = @plans.index{|e| e.id == enrolled_plan.id}
            @plans[plan_index] = enrolled_plan
          end
        end
      end
    end
  end

  def thousand_ceil(num)
    return 0 if num.blank?
    (num.fdiv 1000).ceil * 1000
  end

  def set_kind_for_market_and_coverage
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end

  def get_aptc_info_from_session(hbx_enrollment)
    # TODO: This can be removed once we get rid of temporary config.
    # rubocop:disable Style/IfInsideElse
    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      aptc_grants(@person.primary_family, hbx_enrollment.effective_on.year) if @person.present?
    else
      @shopping_tax_household = get_shopping_tax_household_from_person(@person, hbx_enrollment.effective_on.year) if @person.present?
    end
    if @shopping_tax_household.present? || @aptc_grants.present?
      @max_aptc = session[:max_aptc].to_f
      @elected_aptc = session[:elected_aptc].to_f
    else
      @max_aptc = 0
      @elected_aptc = 0
    end
    # rubocop:enable Style/IfInsideElse
  end

  def aptc_grants(family, year)
    return @aptc_grants if defined? @aptc_grants

    result = ::Operations::PremiumCredits::FindAll.new.call({ family: family, year: year, kind: 'AdvancePremiumAdjustmentGrant' })
    @aptc_grants = result.value! if result.success?
  end

  def can_apply_aptc?(plan)
    return false if @enrollment.is_shop?

    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      @aptc_grants.present? and @elected_aptc > 0 and plan.present? and plan.can_use_aptc?
    else
      @shopping_tax_household.present? and @elected_aptc > 0 and plan.present? and plan.can_use_aptc?
    end
  end

  def set_elected_aptc_by_params(elected_aptc)
    return if session[:elected_aptc].to_d == elected_aptc.to_d
    aptc = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
             recalcuate_elected_aptc(elected_aptc)
           else
             elected_aptc.to_f
           end
    session[:elected_aptc] = aptc
  end

  def recalcuate_elected_aptc(elected_aptc)
    return 0.0 if session[:max_aptc].to_f.zero?

    default_aptc_percentage = EnrollRegistry[:enroll_app].setting(:default_aptc_percentage).item
    percentage = [elected_aptc.to_f / session[:max_aptc], default_aptc_percentage.to_f / 100].min
    max_aptc = ::Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: @enrollment, effective_on: @enrollment.effective_on }).value!.to_f
    percentage * max_aptc
  end

  def validate_rating_address
    return unless @market_kind == "individual"
    return if @hbx_enrollment.rating_area_id.present?

    flash[:error] = l10n("insured.out_of_state_error_message")
    redirect_to family_account_path
  end
end
