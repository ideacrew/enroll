# frozen_string_literal: true

# the methods in this helper are used in the views to display data
# for the hbx admin 'create_eligibility' functionality
module HbxAdminHelper
  def primary_member(person_id)
    Person.find(person_id).try(:primary_family).try(:primary_family_member).try(:person) == Person.find(person_id)
  end

  def find_enrollment(hbx_id)
    HbxEnrollment.find(hbx_id)
  end

  def active_eligibility?(family)
    family.active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year) ? 'Yes' : 'No'
  end

  def mthh_active_eligibility?(eligible_member_ids, family_member_id)
    return 'No' if eligible_member_ids.blank?

    eligible_member_ids.include?(family_member_id.to_s) ? 'Yes' : 'No'
  end

  def reinstatement_failure_message(enrollment)
    return "" unless (enrollment.can_be_reinstated? == false) || enrollment.has_active_term_or_expired_exists_for_reinstated_date? || employee_eligibility_status(enrollment)
    return reinstate_failure_reason_message(enrollment) if enrollment.can_be_reinstated? == false
    return l10n("exchange.employer_applications.reinstate.coverage_exists") + enrollment.fetch_term_or_expiration_date.next_day if enrollment.has_active_term_or_expired_exists_for_reinstated_date?
    return l10n("exchange.employer_applications.reinstate.cobra_not_active") if employee_eligibility_status(enrollment) == "CobraTerminated"
    l10n("exchange.employer_applications.reinstate.employee_not_active")
  end

  def reinstate_failure_reason_message(enrollment)
    return l10n("exchange.employer_applications.reinstate.not_eligible_term_reason") if enrollment.term_reason_eligible_for_reinstate?
    return l10n("exchange.employer_applications.reinstate.ivl_term", date: enrollment.fetch_term_or_expiration_date.next_day) unless enrollment.market_name == "Employer Sponsored"
    return l10n("exchange.employer_applications.reinstate.employer_cobra") if enrollment.employee_role.is_cobra_status? && !(enrollment.is_shop? && enrollment.is_cobra_status?)
    return l10n("exchange.employer_applications.reinstate.cobra_employee") if !enrollment.employee_role.is_cobra_status? && (enrollment.is_shop? && enrollment.is_cobra_status?)
    l10n("exchange.employer_applications.reinstate.esi_coverage_date") + enrollment.fetch_term_or_expiration_date.next_day
  end

  def prior_py_sep?(family, effective_date, market)
    return false if effective_date.blank?
    person = family.primary_person
    ivl_prior_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.previous_benefit_coverage_period
    if market == 'individual'
      ivl_prior_coverage_period&.contains?(effective_date)
    else
      person.active_employee_roles.any?{|e| e.census_employee&.benefit_sponsorship&.prior_py_benefit_application&.benefit_sponsor_catalog&.effective_period&.cover?(effective_date)}
    end
  end
end
