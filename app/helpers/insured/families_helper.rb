module Insured::FamiliesHelper

  def display_change_tax_credits_button?(hbx_enrollment)
    hbx_enrollment.has_at_least_one_aptc_eligible_member?(hbx_enrollment.effective_on.year) &&
    hbx_enrollment.product.can_use_aptc? &&
    !hbx_enrollment.is_coverall? &&
    hbx_enrollment.coverage_kind != 'dental'
  end

  def plan_shopping_dependent_text(hbx_enrollment)
    subscriber, dependents = hbx_enrollment.hbx_enrollment_members.partition {|h| h.is_subscriber == true }
    if subscriber.present? && dependents.count == 0
      ("<span class='dependent-text'>#{subscriber.first.person.full_name}</span>").html_safe
    elsif subscriber.blank? && dependents.count == 1
      ("<span class='dependent-text'>#{dependents.first.person.full_name}</span>").html_safe
    elsif subscriber.blank? && dependents.count > 1
      (link_to(pluralize(dependents.count, "dependent"), "", data: {toggle: "modal", target: "#dependentsList"}, class: "dependent-text")).html_safe + render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    else
      ("<span class='dependent-text'>#{subscriber.first.person.full_name}</span>" + " + " + link_to(pluralize(dependents.count, "dependent"), "", data: {toggle: "modal", target: "#dependentsList"}, class: "dependent-text")).html_safe + render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    end
  end

  def current_premium hbx_enrollment
    begin
      if hbx_enrollment.is_shop?
        hbx_enrollment.total_employee_cost
      elsif hbx_enrollment.kind == 'coverall'
        hbx_enrollment.total_premium
      else
        hbx_enrollment.total_premium > hbx_enrollment.applied_aptc_amount.to_f ? hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f : 0
      end
    rescue Exception => e
      exception_message = "Current Premium calculation error for HBX Enrollment: #{hbx_enrollment.hbx_id.to_s}"
      Rails.logger.error(exception_message) unless Rails.env.test?
      puts(exception_message) unless Rails.env.test?
      'Not Available.'
    end
  end

  def hide_policy_selected_date?(hbx_enrollment)
    return true if hbx_enrollment.created_at.blank?
    return true if hbx_enrollment.benefit_group.present? && hbx_enrollment.benefit_group.is_congress && hbx_enrollment.created_at <= Time.zone.parse("2015-11-09 14:00:00").utc
    return true if !hbx_enrollment.consumer_role_id.blank? && hbx_enrollment.created_at <= Time.zone.parse("2015-10-13 14:00:00").utc
    false
  end

  def shift_purchase_time(policy)
    policy.created_at.in_time_zone('Eastern Time (US & Canada)')
  end

  def shift_waived_time(policy)
    (policy.submitted_at || policy.created_at).in_time_zone('Eastern Time (US & Canada)')
  end

  def format_policy_purchase_date(policy)
    format_date(shift_purchase_time(policy))
  end

  def format_policy_purchase_time(policy)
    shift_purchase_time(policy).strftime("%-I:%M%p")
  end

  def format_policy_waived_date(policy)
    format_date(shift_waived_time(policy))
  end

  def format_policy_waived_time(policy)
    shift_waived_time(policy).strftime("%-I:%M%p")
  end

  def render_plan_type_details(plan)
    plan_details = [plan.try(:product_type).try(:upcase)].compact

    metal_level = display_dental_metal_level(plan)

    if plan_level = plan.try(:metal_level).try(:humanize)
      plan_details << "<span class=\"#{plan_level.try(:downcase)}-icon\">#{metal_level}</span>"
    end

    if plan.try(:nationwide)
      plan_details << "NATIONWIDE NETWORK"
    end

    plan_details.inject([]) do |data, element|
      data << "#{element}"
    end.join("&nbsp<label class='separator'></label>").html_safe
  end

  def render_product_type_details(metal_level_kind, nationwide)
    product_details = []

    if metal_level_kind
      product_level = metal_level_kind.to_s.try(:humanize)
      product_details << "<span class=\"#{product_level.try(:downcase)}-icon\">#{product_level.titleize}</span>"
    end

    product_details << 'NATIONWIDE NETWORK' if nationwide

    product_details.inject([]) do |data, element|
      data << element.to_s
    end.join("&nbsp<label class='separator'></label>").html_safe
  end

  def qle_link_generater(qle, index)
    options = {class: 'qle-menu-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      is_self_attested: qle.is_self_attested,
      current_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y"),
      qle_event_date_kind: qle.qle_event_date_kind.to_s
    }

    if qle.tool_tip.present?
      data.merge!(toggle: 'tooltip', placement: index > 2 ? 'top' : 'bottom')
      options.merge!(data: data, title: qle.tool_tip)
    else
      options.merge!(data: data)
    end

    qle_title_html = "<u>#{qle.title}</u>".html_safe if qle.reason == 'covid-19'
    
    link_to qle_title_html || qle.title, "javascript:void(0)", options
  end

  def qle_link_generator_for_an_existing_qle(qle, link_title=nil)
    options = {class: 'existing-sep-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      is_self_attested: qle.is_self_attested,
      current_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    }
    options.merge!(data: data)
    link_to link_title.present? ? link_title: "Shop for Plans", "javascript:void(0)", options
  end

  def generate_options_for_effective_on_kinds(effective_on_kinds, qle_date)
    return [] if effective_on_kinds.blank?

    options = []
    effective_on_kinds.each do |kind|
      case kind
      when 'date_of_event'
        options << [qle_date.to_s, kind]
      when 'first_of_this_month'
        options << [qle_date.beginning_of_month.to_s, kind]
      when 'fixed_first_of_next_month'
        options << [(qle_date.end_of_month + 1.day).to_s, kind]
      end
    end

    options
  end

  def newhire_enrollment_eligible?(employee_role)
    return false if employee_role.blank? || employee_role.census_employee.blank?

    employee_role.census_employee.newhire_enrollment_eligible? && employee_role.can_select_coverage?
  end

  def has_writing_agent?(employee_role)
    employee_role.employer_profile.active_broker_agency_account.writing_agent rescue false
  end

  def disable_make_changes_button?(hbx_enrollment)
    # return false if IVL
    return false if hbx_enrollment.census_employee.blank?
    return false if !hbx_enrollment.is_shop?
    # Enable the button under these conditions
      # 1) plan year under open enrollment period
      # 2) new hire covered under enrolment period
      # 3) qle enrolmlent period check
    return false if hbx_enrollment.sponsored_benefit_package.open_enrollment_contains?(TimeKeeper.date_of_record)
    return false if hbx_enrollment.employee_role &. can_enroll_as_new_hire?
    return false if hbx_enrollment.family.is_under_special_enrollment_period? && hbx_enrollment.active_during?(hbx_enrollment.family.current_sep.effective_on)

    # Disable only  if non of the above conditions match
    true
  end

  def all_active_enrollment_with_aptc(family)
    family.active_household.active_hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
  end

  def hbx_member_names(hbx_enrollment_members)
    member_names = Array.new
    hbx_enrollment_members.each do |hem|
      member_names.push(Person.find(hem.family_member.person_id.to_s).full_name)
    end
    return member_names.join(", ")
  end

  def has_writing_agent?(employee_role_or_person)
    if employee_role_or_person.is_a?(EmployeeRole)
      employee_role_or_person.employer_profile.active_broker_agency_account.writing_agent rescue false
    elsif employee_role_or_person.is_a?(Person)
       employee_role_or_person.primary_family.current_broker_agency.writing_agent.present? rescue false
    end
  end

  def display_aasm_state?(enrollment)
    if enrollment.is_shop?
      true
    elsif enrollment.is_ivl_actively_outstanding?
      false
    else
      ['coverage_selected', 'coverage_canceled', 'coverage_terminated', 'auto_renewing', 'renewing_coverage_selected', 'coverage_expired'].include?(enrollment.aasm_state.to_s)
    end
  end

  def formatted_enrollment_states
    {
      'coverage_terminated' => 'Terminated',
      'coverage_expired' => 'Coverage Period Ended'
    }
  end

  def enrollment_coverage_end(hbx_enrollment)
    if hbx_enrollment.coverage_terminated? || hbx_enrollment.coverage_termination_pending?
      hbx_enrollment.terminated_on
    elsif hbx_enrollment.coverage_expired?
      if hbx_enrollment.is_shop? && hbx_enrollment.benefit_group_assignment&.benefit_package.present?
        hbx_enrollment.benefit_group_assignment.benefit_package.end_on
      else
        benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.by_date(hbx_enrollment.effective_on).first
        if benefit_coverage_period
          benefit_coverage_period.end_on
        else
          hbx_enrollment.effective_on.end_of_year
        end
      end
    end
  end

  def build_link_for_sep_type(sep, link_title=nil)
    return if sep.blank?
    qle = QualifyingLifeEventKind.find(sep.qualifying_life_event_kind_id)
    return if qle.blank?
    if qle.date_options_available && sep.optional_effective_on.present?
      # Take to the QLE like flow of choosing Option dates if available
       qle_link_generator_for_an_existing_qle(qle, link_title)
    else
      # Take straight to the Plan Shopping - Add Members Flow. No date choices.
      # Use turbolinks: false, to avoid calling controller action twice.
      link_to link_title.presence || 'Shop for Plans', insured_family_members_path(sep_id: sep.id, qle_id: qle.id), class: 'btn btn-default', data: {turbolinks: false}
    end
  end

  def find_qle_for_sep(sep)
    QualifyingLifeEventKind.find(sep.qualifying_life_event_kind_id)
  end

  def person_has_any_roles?
    @person.consumer_role.present? || @person.resident_role.present? || @person.active_employee_roles.any?
  end

  def is_strictly_open_enrollment_case?
    is_under_open_enrollment? && @family.active_seps.blank?
  end

  def tax_info_url
    if ENV['AWS_ENV'] == 'prod'
      "https://dchealthlink.com/individuals/tax-documents"
    else
      "https://staging.dchealthlink.com/individuals/tax-documents"
    end
  end

  def show_download_tax_documents_button?
    if @person.ssn.blank?
      false
    elsif @person.consumer_role.blank?
      false
    elsif @person.consumer_role.present?
      true
    end
  end
  def is_applying_coverage_value_personal(person)
    first_checked = true
    second_checked = false
    if person.consumer_role.present?
      first_checked = person.consumer_role.is_applying_coverage
      second_checked = !person.consumer_role.is_applying_coverage
    end
    return first_checked, second_checked
  end

  def current_market_kind(person)
    if person.is_consumer_role_active? || person.is_resident_role_active?
      person.active_individual_market_role
    else
      "No Consumer/CoverAll Market"
    end
  end

  def new_market_kind(person)
    if person.is_consumer_role_active?
      "resident"
    elsif person.is_resident_role_active?
      "consumer"
    else
      " - "
    end
  end

  def build_consumer_role(person, family)
    if family.primary_applicant.person == person
      contact_method = person.resident_role&.contact_method ? person.resident_role.contact_method : "Paper and Electronic communications"
      person.build_consumer_role({:is_applicant => true, :contact_method => contact_method})
      person.save!
    else
      person.build_consumer_role({:is_applicant => false})
      person.save!
    end
  end

  def build_resident_role(person, family)
    if family.primary_applicant.person == person
      contact_method = person.consumer_role&.contact_method ? person.consumer_role.contact_method : "Paper and Electronic communications"
      person.build_resident_role({:is_applicant => true, :contact_method => contact_method })
      person.save!
    else
      person.build_resident_role({:is_applicant => false})
      person.save!
    end
  end

  def transition_reason(person)
    if person.is_consumer_role_active?
      @qle = QualifyingLifeEventKind.where(reason: 'eligibility_failed_or_documents_not_received_by_due_date').first
      { @qle.title => @qle.reason }
    elsif person.is_resident_role_active?
      @qle = QualifyingLifeEventKind.where(reason: 'eligibility_documents_provided').first
      { @qle.title => @qle.reason }
    end
  end

  def enable_make_changes_button?(hbx_enrollment)
    hbx_enrollment.is_ivl_by_kind? && ['coverage_selected', 'auto_renewing', 'unverified', 'renewing_coverage_selected', 'transmitted_to_carrier'].include?(hbx_enrollment.aasm_state)
  end
end
