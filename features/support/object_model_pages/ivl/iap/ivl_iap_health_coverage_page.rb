# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/benefits
class IvlIapHealthCoveragePage

  def self.has_enrolled_health_coverage_yes_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?

    else
    '#has_enrolled_health_coverage_true'
    end
  end

  def self.has_enrolled_health_coverage_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?

    else
    '#has_enrolled_health_coverage_false'
    end
  end

  def self.not_sure_has_enrolled_health_coverage_link
    'a[href="#has_enrolled_health_coverage"]'
  end

  def self.dc_individual_family_coverage_checkbox
    'input[value="private_individual_and_family_coverage"]'
  end

  def self.from
    'benefit[start_on]'
  end

  def self.calendar
    '#ui-datepicker-div'
  end

  def self.to
    'benefit[end_on]'
  end

  def self.cancel_btn
    'a[class="btn btn-default benefit-cancel interaction-click-control-cancel"]'
  end

  def self.save_btn
    'input[class="btn btn-danger interaction-click-control-save"]'
  end

  def self.acf_refugee_medical_assistance_checkbox
    'input[value="acf_refugee_medical_assistance"]'
  end

  def self.americorps_health_benefits_checkbox
    'input[value="americorps_health_benefits"]'
  end

  def self.childrens_health_insurance_program_checkbox
    'input[value="child_health_insurance_plan"]'
  end

  def self.medicaid_checkbox
    'input[value="medicaid"]'
  end

  def self.medicare_checkbox
    'input[value="medicare"]'
  end

  def self.medicare_advantage_checkbox
    'input[value="medicare_advantage"]'
  end

  def self.medicare_part_b_checkbox
    'input[value="medicare_part_b"]'
  end

  def self.state_supplementary_payment_checkbox
    'input[value="state_supplementary_payment"]'
  end

  def self.tricare_checkbox
    'input[value="tricare"]'
  end

  def self.veterans_benefits_checkbox
    'input[value="veterans_benefits"]'
  end

  def self.naf_health_benefit_program_checkbox
    'input[value="naf_health_benefit_program"]'
  end

  def self.health_care_for_peace_corp_volunteers_checkbox
    'input[value="health_care_for_peace_corp_volunteers"]'
  end

  def self.department_of_defense_non_appropriated_health_benefits_checkbox
    'input[value="department_of_defense_non_appropriated_health_benefits"]'
  end

  def self.cobra_checkbox
    'input[value="cobra"]'
  end

  def self.employer_sponsored_health_coverage_checkbox
    'input[value="employer_sponsored_insurance"]'
  end

  def self.self_funded_student_health_coverage_checkbox
    'input[value="self_funded_student_health_coverage"]'
  end

  def self.foreign_government_health_coverage_checkbox
    'input[value="foreign_government_health_coverage"]'
  end

  def self.private_health_insurance_plan_checkbox
    'input[value="private_health_insurance_plan"]'
  end

  def self.employer_name
    'benefit[employer_name]'
  end

  def self.employer_address
    'benefit[employer_address][address_1]'
  end

  def self.employer_city
    'benefit[employer_address][city]'
  end

  def self.employer_zip
    'benefit[employer_address][zip]'
  end

  def self.employer_state_dropdown
    'div[class="selectric-wrapper selectric-interaction-choice-control-benefit-employer-address-state"]'
  end

  def self.select_california
    'li[class="interaction-choice-control-benefit-employer-address-state-5 interaction-choice-control-benefit-esi-covered-5 interaction-choice-control-benefit-employee-cost-frequency-5"]'
  end

  def self.employer_id
    'benefit_employer_id'
  end

  def self.employer_phone_number
    'benefit_employer_phone_full_phone_number'
  end

  def self.employee_waiting_period_yes_radiobtn
    'label[for*="benefit_is_esi_waiting_period"][for*="true"] span'
  end

  def self.employee_waiting_period_no_radiobtn
    'label[for*="benefit_is_esi_waiting_period] [for#="false"] span'
  end

  def self.employee_waiting_period_not_sure_link
    'a[class="interaction-click-control-not-sure? benefit-support-modal"]'
  end

  def self.employer_offer_standard_health_plan_yes_radiobtn
    'label[for="benefit_is_esi_mec_met_60ab8f21297c6a0957e939f9_true"]'
  end

  def self.coverage_obtained_through_another_exchange_checkbox
    'input[value="coverage_obtained_through_another_exchange"]'
  end

  def self.coverage_under_the_state_health_benefits_risk_pool_checkbox
    'input[value="coverage_under_the_state_health_benefits_risk_pool"]'
  end

  def self.veterans_administration_health_benefits_checkbox
    'input[value="veterans_administration_health_benefits"]'
  end

  def self.peace_corps_health_benefits_checkbox
    'input[value="peace_corps_health_benefits"]'
  end

  def self.has_eligible_health_coverage_yes_radiobtn
    '#has_eligible_health_coverage_true'
  end

  def self.has_eligible_health_coverage_no_radiobtn
    '#has_eligible_health_coverage_false'
  end

  def self.not_sure_has_eligible_health_coverage_link
    'a[href="#has_eligible_health_coverage"]'
  end

  def self.continue
    '.interaction-click-control-continue'
  end

  def self.back_to_all_house_members
    'a[class=interaction-click-control-back-to-all-household-members]'
  end

  def self.medicare
    '.medicare'
  end

  def self.medicare_glossary_link
    '.medicare span'
  end

  def self.coverage_obtained_through_another_exchange
    '.coverage_obtained_through_another_exchange'
  end

  def self.coverage_obtained_through_another_exchange_glossary_link
    '.coverage_obtained_through_another_exchange span'
  end

  def self.has_eligible_medicaid_cubcare_false
    '#has_eligible_medicaid_cubcare_false'
  end

  def self.has_eligibility_changed_false
    '#has_eligibility_changed_false'
  end

  def self.mainecare_ineligible_question_text
    "Was this person found not eligible for MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) based on their immigration status since"
  end
end
