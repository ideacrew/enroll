module SepAll
  include ::ParseDateHelper

  def calculateDates
    @family = Family.find(params[:person]) if params[:person].present?

    if params[:effective_kind] == '15th of month'
      params[:effective_kind] = 'first of month'
    elsif params[:effective_kind] == 'End of Month'
      params[:effective_kind] = 'first of next month'
    elsif params[:effective_kind] == 'First of month after event'
      params[:effective_kind] = 'fixed first of next month'
    else
      #Do Nothing
    end

    qle = QualifyingLifeEventKind.find(params[:id]) if params[:id].present?

    if qle.reason == 'covid-19'
      @eff_kind = params[:effective_kind]
    else
      @eff_kind = params[:effective_kind].split.join("_").downcase
    end

    special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: @eff_kind)
    special_enrollment_period.qualifying_life_event_kind = qle
    special_enrollment_period.qle_on = parse_date(params[:eventDate])
    @start_on = special_enrollment_period.start_on
    @end_on = special_enrollment_period.end_on
    @effective_on = special_enrollment_period.effective_on
    @self_attested = qle.is_self_attested
    @date_options = qle.date_options_available
    @market_kind = qle.market_kind
  end

  def check_renewal_flag
    @family = Family.find(params[:person]) if params[:person].present?
    qle = QualifyingLifeEventKind.find(params[:id]) if params[:id].present?
    effective_date = parse_date(params[:effective_date]) if params[:effective_date].present?
    date_option_1 = parse_date(params[:date_option1]) if params[:date_option1].present?
    date_option_2 = parse_date(params[:date_option2]) if params[:date_option2].present?
    date_option_3 = parse_date(params[:date_option3]) if params[:date_option3].present?

    status = []
    [effective_date, date_option_1, date_option_2, date_option_3].each do |date|
      status << prior_py_sep?(@family, date, qle.market_kind)
    end
    status.include?(true)
  end

  def prior_py_sep?(family, effective_date, market)
    return false if market.blank?
    return prior_py_ivl_sep?(effective_date) if market == 'individual'

    prior_py_shop_sep?(family, effective_date)
  end

  def prior_py_shop_sep?(family, effective_date)
    return false if family.blank?
    return false if effective_date.blank?

    person = family.primary_person
    person.active_employee_roles.any?{|e| e.census_employee&.benefit_sponsorship&.prior_py_benefit_application&.benefit_sponsor_catalog&.effective_period&.cover?(effective_date)}
  end

  def prior_py_ivl_sep?(effective_date)
    ivl_prior_coverage_period = HbxProfile.current_hbx&.benefit_sponsorship&.previous_benefit_coverage_period
    return false if ivl_prior_coverage_period.blank?
    return false if effective_date.blank?

    ivl_prior_coverage_period&.contains?(effective_date)
  end

  def calculate_rule
    fifteen_day_rule = '15th of month'
    end_month_rule = 'End of Month'
    next_month_event_rule = 'First of month after event'

    if @qle.reason == 'covid-19'
      qle_on = TimeKeeper.date_of_record
      @effective_kinds = @qle.effective_on_kinds.map do |t|
        if t == 'first_of_this_month'
          [qle_on.beginning_of_month.to_s, t]
        elsif t == 'fixed_first_of_next_month'
          [(qle_on.end_of_month + 1.day).to_s, t]
        end
      end
    else
      @effective_kinds = @qle.effective_on_kinds.map do |t|
        if t == 'first_of_month'
          fifteen_day_rule
        elsif t == 'first_of_next_month'
          end_month_rule
        elsif t == 'fixed_first_of_next_month'
          next_month_event_rule
        else
          t.humanize
        end
      end
    end
  end

  def getActionParams
    @row = params[:row]
    @family = Family.find(params[:family])
    getMarket(@family)
    respond_to do |format|
      format.js {}
    end
  end

  def getMarket(family)
    consumer_role = family.primary_applicant.person.consumer_role
    resident_role = family.primary_applicant.person.resident_role
    employee_roles = family.primary_applicant.person.active_employee_roles

    @qle_ivl = QualifyingLifeEventKind.qualifying_life_events_for(consumer_role || resident_role, true)
    @qle_shop = QualifyingLifeEventKind.qualifying_life_events_for(employee_roles.first, true)

    if employee_roles.present?
      @qle = @qle_shop if consumer_role.blank?
    end

    @qle = @qle_ivl  if consumer_role.present?
    @qle ||= @qle_ivl

    @market = 'both' if consumer_role.present? && employee_roles.present?
  end

  def includeBothMarkets
    dt_query = extract_datatable_parameters
    families_dt = []
    all_families = Family.all
    if dt_query.search_string.blank?
      families_dt = all_families
    else
      person_ids = Person.search(dt_query.search_string).pluck(:id)
      families_dt = all_families.where({
      "family_members.person_id" => {"$in" => person_ids}
      })
    end

    @draw = dt_query.draw
    @state = 'both'
    @total_records = sortData(all_families, @state)
    @records_filtered = sortData(families_dt, @state)
    @dataArray = sortData(families_dt, @state, 'yes')
    @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
  end

  def includeIVL
    if QualifyingLifeEventKind.where(:market_kind => 'individual').present?
      all_families_in_ivl = Family.all
      dt_query = extract_datatable_parameters
      families_dt = []

      if dt_query.search_string.blank?
        families_dt = all_families_in_ivl
      else
        person_ids = Person.search(dt_query.search_string).pluck(:id)
        families_dt = all_families_in_ivl.where({
        "family_members.person_id" => {"$in" => person_ids}
        })
      end

      @draw = dt_query.draw
      @state = 'ivl'
      @total_records = sortData(all_families_in_ivl, @state)
      @records_filtered = sortData(families_dt, @state)
      @dataArray = sortData(families_dt, @state, 'yes')
      @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
    end
  end

  def includeShop
    if QualifyingLifeEventKind.where(:market_kind => 'shop').present?
      all_families_in_shop = Family.all
      dt_query = extract_datatable_parameters
      families_dt = []

      if dt_query.search_string.blank?
        families_dt = all_families_in_shop
      else
        person_ids = Person.search(dt_query.search_string).pluck(:id)
        families_dt = all_families_in_shop.where({
        "family_members.person_id" => {"$in" => person_ids}
        })
      end

      @draw = dt_query.draw
      @state = 'shop'
      @total_records = sortData(all_families_in_shop, @state)
      @records_filtered = sortData(families_dt, @state)
      @dataArray = sortData(families_dt, @state, 'yes')
      @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
    end
  end

  def createSep
    qle = QualifyingLifeEventKind.find(sep_params[:qle_id])
    @family = Family.find(sep_params[:person])
    @name = sep_params[:firstName] + " " + sep_params[:lastName]
    special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: sep_params[:effective_on_kind].downcase)
    special_enrollment_period.qualifying_life_event_kind = qle
    special_enrollment_period.qle_on = parse_date(sep_params[:event_date]) if sep_params[:event_date].present?
    special_enrollment_period.start_on = parse_date(sep_params[:start_on]) if sep_params[:start_on].present?
    special_enrollment_period.end_on = parse_date(sep_params[:end_on]) if sep_params[:end_on].present?
    special_enrollment_period.selected_effective_on = sep_params[:effective_on_date] if sep_params[:effective_on_date].present?
    # special_enrollment_period.admin_comment = params.permit(:admin_comment)[:admin_comment] if sep_params[:admin_comment].present?
    special_enrollment_period.comments << Comment.new(content: sep_params[:admin_comment], user: current_user.email) if sep_params[:admin_comment].present?
    special_enrollment_period.csl_num = sep_params[:csl_num] if sep_params[:csl_num].present?
    special_enrollment_period.next_poss_effective_date = parse_date(sep_params[:next_poss_effective_date]) if sep_params[:next_poss_effective_date].present?
    date_arr = Array.new
    date_arr.push(parse_date(sep_params[:option1_date]).to_s) if sep_params[:option1_date].present?
    date_arr.push(parse_date(sep_params[:option2_date]).to_s) if sep_params[:option2_date].present?
    date_arr.push(parse_date(sep_params[:option3_date]).to_s) if sep_params[:option3_date].present?
    special_enrollment_period.optional_effective_on = date_arr if date_arr.length > 0
    special_enrollment_period.market_kind = qle.market_kind == "individual" ? "ivl" : qle.market_kind
    special_enrollment_period.admin_flag = true
    special_enrollment_period.coverage_renewal_flag = sep_params[:coverage_renewal_flag].to_s == "true"
    
    if special_enrollment_period.save
      @message_for_partial = @bs4 ? l10n('hbx_profiles.add_sep.result.success', name: @name) : "SEP Added for #{@name}"
    else
      errors = special_enrollment_period.errors.full_messages.join(", ")
      @message_for_partial = @bs4 ? l10n('hbx_profiles.add_sep.result.failure', errors: errors) : "SEP not saved. (Error: #{errors})"
    end
  end

  def sortData(families, state, returnData=nil)
    init_arr = []
    if (state == 'both')
      families.each do|f| 
        if f.primary_applicant.person.consumer_role.present? || f.primary_applicant.person.active_employee_roles.present?        
          init_arr.push(f)
        end
      end
    elsif (state == 'ivl')
      families.each do|f|
        if f.primary_applicant.person.consumer_role.present? 
          init_arr.push(f)
        end
      end
    else
      families.each do|f|
        if f.primary_applicant.person.active_employee_roles.present?
          init_arr.push(f)
        end
      end
    end
   returnData == 'yes' ? init_arr : init_arr.length;
  end
end
