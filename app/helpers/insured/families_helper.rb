# frozen_string_literal: true

module Insured::FamiliesHelper
  include FloatHelper
  include HtmlScrubberUtil

  def display_change_tax_credits_button?(hbx_enrollment)
    hbx_enrollment.has_at_least_one_aptc_eligible_member?(hbx_enrollment.effective_on.year) &&
    hbx_enrollment.product.can_use_aptc? &&
    !hbx_enrollment.is_coverall? &&
    hbx_enrollment.coverage_kind != 'dental'
  end

  def plan_shopping_dependent_text(hbx_enrollment)
    subscriber, dependents = hbx_enrollment.hbx_enrollment_members.partition {|h| h.is_subscriber == true }
    if subscriber.present? && dependents.count == 0
      sanitize_html("<span class='dependent-text'>#{subscriber.first.person.full_name}</span>")
    elsif subscriber.blank? && dependents.count == 1
      sanitize_html("<span class='dependent-text'>#{dependents.first.person.full_name}</span>")
    elsif subscriber.blank? && dependents.count > 1
      link_to(
        pluralize(dependents.count, "dependent"),
        "",
        data: {toggle: "modal", target: "#dependentsList"},
        class: "dependent-text"
      ) +
        render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    else
      sanitize_html("<span class='dependent-text'>#{subscriber.first.person.full_name}</span> + ") +
        link_to(pluralize(dependents.count, "dependent"), "", data: {toggle: "modal", target: "#dependentsList"}, class: "dependent-text") +
        render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    end
  end

  def current_premium hbx_enrollment
    begin
      if hbx_enrollment.is_shop?
        hbx_enrollment.total_employee_cost
      else
        cost = float_fix(hbx_enrollment.total_premium - [hbx_enrollment.total_ehb_premium, hbx_enrollment.applied_aptc_amount.to_f].min - hbx_enrollment.eligible_child_care_subsidy.to_f)
        cost > 0 ? cost.round(2) : 0
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

    sanitize_html(
      plan_details.inject([]) do |data, element|
        data << element.to_s
      end.join("&nbsp;<label class='separator'></label>")
    )
  end

  def render_product_type_details(metal_level_kind, nationwide)
    product_details = []

    if metal_level_kind
      product_level = metal_level_kind.to_s.try(:humanize)
      product_details << "<span class=\"#{product_level.try(:downcase)}-icon\">#{product_level.titleize}</span>"
    end

    product_details << 'NATIONWIDE NETWORK' if nationwide

    sanitize_html(
      product_details.inject([]) do |data, element|
        data << element.to_s
      end.join("&nbsp;<label class='separator'></label>")
    )
  end

  def qle_link_generator(qle, index)
    options = {class: 'qle-menu-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      is_self_attested: qle.is_self_attested,
      current_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y"),
      qle_event_date_kind: qle.qle_event_date_kind.to_s,
      reason: qle.reason
    }

    if qle.tool_tip.present?
      data.merge!(toggle: 'tooltip', placement: index > 2 ? 'top' : 'bottom')
      options.merge!(data: data, title: qle.tool_tip)
    else
      options.merge!(data: data)
    end

    qle_title_html = sanitize_html("<u>#{qle.title}</u>") if qle.reason == 'covid-19'

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

  def generate_options_for_effective_on_kinds(qle, qle_date)
    return [] if qle&.effective_on_kinds.blank?
    qle.effective_on_kinds.collect { |kind| [find_effective_on(qle, qle_date, kind).to_s, kind] }.uniq(&:first)
  end

  def find_effective_on(qle, qle_date, kind)
    special_enrollment_period = SpecialEnrollmentPeriod.new(effective_on_kind: kind)
    special_enrollment_period.qualifying_life_event_kind = qle
    special_enrollment_period.qle_on = qle_date
    special_enrollment_period.effective_on
  end

  def newhire_enrollment_eligible?(employee_role)
    return false if employee_role.blank? || employee_role.census_employee.blank?
    employee_role.can_enroll_as_new_hire?
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

  def formatted_enrollment_states(enrollment)
    enrollment_states_hash = if display_termination_reason?(enrollment)
                               {
                                 'coverage_terminated' => 'Terminated by health insurer',
                                 'coverage_canceled' => 'Canceled by health insurer',
                                 'coverage_expired' => 'Coverage Period Ended'
                               }
                             else
                               {
                                 'coverage_terminated' => 'Terminated',
                                 'coverage_expired' => 'Coverage Period Ended'
                               }
                             end
    enrollment_states_hash.stringify_keys[enrollment.aasm_state.to_s]
  end

  # Generates an HTML label for the given hbx enrollment object based on its aasm state and other attributes.
  # The label provides a visual representation of the enrollment state with text and color.
  #
  # @param enrollment [Object] The hbx enrollment object for which the label is generated.
  # @return [String, nil] An HTML string representing the label or nil if the enrollment is blank.
  def enrollment_state_label(enrollment, bs4)
    return if enrollment.blank?

    # The colors correspond to those set in enrollment.scss as label-{color}. We use color as an indicator of the
    # enrollment status. For example, green indicates that the enrollment is active, red indicates that the enrollment
    # is terminated, yellow indicates that the enrollment requires action, etc.
    state_groups = {
      auto_renewing: {
        has_outstanding_verification: { text: 'Action Needed', color: 'yellow' },
        default: { text: 'Auto Renewing', color: 'green' }
      },
      coverage_canceled: {
        non_payment: { text: 'Canceled by Insurance Company', color: 'red' },
        default: { text: 'Coverage Canceled', color: 'grey' }
      },
      coverage_expired: {
        default: { text: 'Coverage Year Ended', color: 'blue' }
      },
      coverage_reinstated: {
        default: { text: 'Coverage Reinstated', color: 'green' }
      },
      coverage_selected: {
        has_outstanding_verification: { text: 'Action Needed', color: 'yellow' },
        default: { text: 'Coverage Selected', color: 'green' }
      },
      coverage_terminated: {
        non_payment: { text: 'Terminated by Insurance Company', color: 'red' },
        default: { text: 'Terminated', color: 'blue' }
      },
      renewing_coverage_selected: {
        has_outstanding_verification: { text: 'Action Needed', color: 'yellow' },
        default: { text: 'Renewing Coverage Selected', color: 'green' }
      },
      unverified: {
        has_outstanding_verification: { text: 'Action Needed', color: 'yellow' }
      },
      default: {
        has_outstanding_verification: { text: 'Action Needed', color: 'yellow' }
      }
    }

    group = state_groups[enrollment.aasm_state.to_sym] || state_groups[:default]
    condition = determine_condition(enrollment, group)
    label = group[condition] || { text: enrollment.aasm_state.to_s.titleize, color: 'grey' }
    # Coverage reinstated is a special case where the aasm state is something else but we want to show it as reinstated in "green" (active) scenarios
    label = state_groups[:coverage_reinstated][:default] if enrollment.is_reinstated_enrollment? && label[:color] == 'green'
    return content_tag(:span, label[:text], class: "label label-#{label[:color]}") unless bs4
    content_tag(:span, label[:text], class: "badge badge-pill badge-status badge-#{label[:color]}")
  end

  def determine_condition(enrollment, enrollment_state)
    if display_termination_reason?(enrollment) && enrollment_state.key?(:non_payment)
      :non_payment
    elsif enrollment.is_any_enrollment_member_outstanding && enrollment_state.key?(:has_outstanding_verification)
      :has_outstanding_verification
    else
      :default
    end
  end

  def display_termination_reason?(enrollment)
    return false if enrollment.is_shop?
    enrollment.terminate_reason && EnrollRegistry.feature_enabled?(:display_ivl_termination_reason) &&
      enrollment.terminate_reason == HbxEnrollment::TermReason::NON_PAYMENT
  end

  def covered_members_name_age(hbx_enrollment_members)
    enrollment_members = hbx_enrollment_members.sort_by { |a| a.is_subscriber ? 0 : 1 }
    enrollment_members.inject([]) do |name_age, member|
      name_age << "#{member.person.first_name} (#{((Time.zone.now - member.person.dob.to_time) / 1.year.seconds).floor})"
    end
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

  def build_link_for_sep_type(sep, link_title = nil, family_id = nil, link_class = nil)
    return if sep.blank?
    qle = QualifyingLifeEventKind.find(sep.qualifying_life_event_kind_id)
    return if qle.blank?
    if qle.date_options_available && sep.optional_effective_on.present?
      # Take to the QLE like flow of choosing Option dates if available
       qle_link_generator_for_an_existing_qle(qle, link_title)
    else
      # Take straight to the Plan Shopping - Add Members Flow. No date choices.
      # Use turbolinks: false, to avoid calling controller action twice.
      # TODO: Refactor Shop For Planss as a translation at some point
      link_path = family_id.present? ? insured_family_members_path(sep_id: sep.id, qle_id: qle.id, family_id: family_id) : insured_family_members_path(sep_id: sep.id, qle_id: qle.id)
      link_to link_title.presence || l10n("insured.shop_for_plans"), link_path, data: {turbolinks: false}, class: link_class
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
      EnrollRegistry[:enroll_app].setting(:prod_tax_info).item
    else
      EnrollRegistry[:enroll_app].setting(:staging_tax_info_url).item
    end
  end

  def show_download_tax_documents_button?
    return false unless EnrollRegistry.feature_enabled?(:show_download_tax_documents)
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
      # TODO: Refactor this as a translation if possible
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
    else
      person.build_consumer_role({:is_applicant => false})
    end
    # All persons with a consumer_role are required to have a demographics_group
    person.build_demographics_group
    person.save!
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

  def fetch_counties_by_zip(address)
    return [] unless address&.zip

    BenefitMarkets::Locations::CountyZip.where(zip: address.zip.slice(/\d{5}/)).pluck(:county_name).uniq
  end

  def all_transitions(enrollment)
    if enrollment.workflow_state_transitions.present?
      all_transitions = []
      enrollment.workflow_state_transitions.each do |transition|
        all_transitions << if enrollment.is_transition_superseded_silent?(transition)
                             l10n('enrollment.latest_transition_data_with_silent_reason',
                                  from_state: transition.from_state,
                                  to_state: transition.to_state,
                                  created_at: transition.created_at.in_time_zone('Eastern Time (US & Canada)').strftime("%m/%d/%Y %-I:%M%p"))
                           else
                             l10n('enrollment.latest_transition_data',
                                  from_state: transition.from_state,
                                  to_state: transition.to_state,
                                  created_at: transition.created_at&.in_time_zone('Eastern Time (US & Canada)')&.strftime("%m/%d/%Y %-I:%M%p"))
                           end
      end
      all_transitions.join("\n")
    else
      l10n('not_available')
    end
  end

  def initially_hide_enrollment?(enrollment)
    canceled_enrollment = enrollment.aasm_state == 'coverage_canceled'
    reason_is_non_payment = enrollment.terminate_reason == 'non_payment' if EnrollRegistry.feature_enabled?(:show_non_pay_enrollments)
    external_enrollment = (enrollment.aasm_state != 'shopping' && enrollment.external_enrollment == true)
    (canceled_enrollment && !reason_is_non_payment) || external_enrollment
  end

  def is_broker_authorized?(current_user, family)
    person = current_user.person
    return false if person.blank?

    logged_user_broker_role = person.broker_role
    logged_user_staff_roles = person.broker_agency_staff_roles.where(aasm_state: 'active')
    return false if logged_user_broker_role.blank? && logged_user_staff_roles.blank? # logged in user is not a broker
    return false if broker_profile_ids(family).blank? # family has no broker

    broker_profile_ids(family).include?(logged_user_broker_role.benefit_sponsors_broker_agency_profile_id) || logged_user_staff_roles.map(&:benefit_sponsors_broker_agency_profile_id).include?(ivl_broker_agency_id(family))
  end

  def is_general_agency_authorized?(current_user, family)
    logged_user_ga_roles = current_user.person&.active_general_agency_staff_roles
    return false if logged_user_ga_roles.blank? # logged in user is not a ga
    return false if broker_profile_ids(family).blank? # family has no broker, hence no ga

    ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(
      :owner_profile_id.in => broker_profile_ids(family),
      :general_agency_accounts => {:"$elemMatch" => {aasm_state: :active, :benefit_sponsrship_general_agency_profile_id.in => logged_user_ga_roles.map(&:benefit_sponsors_general_agency_profile_id)}}
    ).present?
  end

  def is_family_authorized?(current_user, family)
    current_user.person&.primary_family == family
  end

  def broker_profile_ids(family)
    @broker_profile_ids ||= ([ivl_broker_agency_id(family)] + shop_broker_agency_ids(family)).compact
  end

  def ivl_broker_agency_id(family)
    @ivl_broker_agency_id ||= family.current_broker_agency&.benefit_sponsors_broker_agency_profile_id
  end

  def shop_broker_agency_ids(family)
    @shop_broker_agency_ids ||= family.primary_person.active_employee_roles.map do |er|
      er.employer_profile&.active_broker_agency_account&.benefit_sponsors_broker_agency_profile_id
    end.compact
  end
end
