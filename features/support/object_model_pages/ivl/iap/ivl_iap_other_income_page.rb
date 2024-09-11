# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/incomes/other
class IvlIapOtherIncomePage

  def self.has_unemployment_income_yes_radiobtn
    '#has_unemployment_income_true' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.has_unemployment_income_no_radiobtn
    '#has_unemployment_income_false' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.not_sure_has_unemployment_link
    'a[href="#has_unemployment_income"]'
  end

  def self.income_amount
    'income[amount]'
  end

  def self.how_often_dropdown
    '[data-cuke="unemployment-income-how-often-dropdown"]'
  end

  def self.select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.select_weekly
    'li[class="interaction-choice-control-income-frequency-kind-6"]'
  end

  def self.select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.select_yearly
    '.new-unemployment-income-form li.interaction-choice-control-income-frequency-kind-7'
  end

  def self.income_from
    'income[start_on]'
  end

  def self.calendar
    'table[class="ui-datepicker-calendar"]'
  end

  def self.unemployment_cancel_btn
    'a[class="btn btn-default unemployment-income-cancel interaction-click-control-cancel"]'
  end

  def self.unemployment_save_btn
    '[data-cuke="unemployment-income-save-button"]'
  end

  def self.unemployment_edit_btn
    'a[class="unemployment-income-edit edit-pr"]'
  end

  def self.unemployment_delete_btn
    'a[class="unemployment-income-delete"]'
  end

  def self.has_other_income_yes_radiobtn
    '#has_other_income_true' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.has_other_income_no_radiobtn
    '#has_other_income_false' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.not_sure_has_other_income_link
    'a[href="#has_other_income"]'
  end

  def self.has_other_income_save_btn
    '[data-cuke="other-income-save-button"]'
  end

  def self.continue_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-click-control-continue-to-next-step'
    else
      '.interaction-click-control-continue'
    end
  end

  def self.alimony_received_checkbox
    'input[class="other-income-checkbox-alimony_and_maintenance interaction-choice-control-value-other-income-kind"]'
  end

  def self.alimony_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-9 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.alimony_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-12 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.other_income_cancel_btn
    'a[class="btn btn-default other-income-cancel interaction-click-control-cancel"]'
  end

  def self.other_income_save_btn
    'input[class="btn btn-danger interaction-click-control-save"]'
  end

  def self.other_income_edit_btn
    'a[class="other-income-edit edit-pr"]'
  end

  def self.other_income_delete_btn
    'a[class="other-income-delete"]'
  end

  def self.other_income_continue_and_remove_btn
    'button[class="btn btn-primary modal-continue-button interaction-click-control-continue---remove"]'
  end

  def self.other_income_do_not_remove_btn
    'button[class="btn btn-default modal-cancel-button interaction-click-control-don\'t-remove"]'
  end

  def self.add_more_alimony_btn
    'a[class="interaction-click-control-add-more-alimony-received"]'
  end

  def self.capital_gains_checkbox
    'input[class="other-income-checkbox-capital_gains interaction-choice-control-value-other-income-kind"]'
  end

  def self.capital_gains_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-17 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.capital_gains_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-23 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.capital_gains_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-20 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.dividends_checkbox
    'input[class="other-income-checkbox-dividend interaction-choice-control-value-other-income-kind"]'
  end

  def self.dividends_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-25 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.dividends_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-28 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.dividends_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-31 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.interest_checkbox
    'input[class="other-income-checkbox-interest interaction-choice-control-value-other-income-kind"]'
  end

  def self.interest_how_often_dropdown
    '.new-other-income-form.interest span.label'
  end

  def self.interest_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-33 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.interest_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-36 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.interest_select_yearly
    '.new-other-income-form.interest li.interaction-choice-control-income-frequency-kind-7'
  end

  def self.pension_or_retirement_checkbox
    'input[class="other-income-checkbox-pension_retirement_benefits interaction-choice-control-value-other-income-kind"]'
  end

  def self.pension_retirement_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-41 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.pension_retirement_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-44 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.pension_retirement_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-47 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.rent_or_royalties_checkbox
    'input[class="other-income-checkbox-rental_and_royalty interaction-choice-control-value-other-income-kind"]'
  end

  def self.rent_royalties_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-49 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.rent_royalties_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-52 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.rent_royalties_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-55 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.social_security_checkbox
    'input[class="other-income-checkbox-social_security_benefit interaction-choice-control-value-other-income-kind"]'
  end

  def self.social_security_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-57 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.social_security_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-60 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.social_security_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-63 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.american_indian_alaska_native_income_checkbox
    'input[class="other-income-checkbox-american_indian_and_alaskan_native interaction-choice-control-value-other-income-kind"]'
  end

  def self.american_indian_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-65 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.american_indian_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-68 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.american_indian_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-71 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.employer_funded_disability_payments_checkbox
    'input[class="other-income-checkbox-employer_funded_disability interaction-choice-control-value-other-income-kind"]'
  end

  def self.employer_funded_disability_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-73 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.employer_funded_disability_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-76 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.employer_funded_disability_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-79 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.estate_and_trust_checkbox
    'input[class="other-income-checkbox-estate_trust interaction-choice-control-value-other-income-kind"]'
  end

  def self.estate_trust_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-81 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.estate_trust_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-84 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.estate_trust_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-87 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.farming_or_fishing_checkbox
    'input[class="other-income-checkbox-farming_and_fishing interaction-choice-control-value-other-income-kind"]'
  end

  def self.farming_fishing_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-89 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.farming_fishing_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-92 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.farming_fishing_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-95 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.foreign_income_checkbox
    'input[class="other-income-checkbox-foreign interaction-choice-control-value-other-income-kind"]'
  end

  def self.foreign_income_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-97 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.foreign_income_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-100 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.foreign_income_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-103 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.other_taxable_income_checkbox
    'input[class="other-income-checkbox-other interaction-choice-control-value-other-income-kind"]'
  end

  def self.taxable_income_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-105 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.taxable_income_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-108 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.taxable_income_select_yearly
    'interaction-choice-control-income-frequency-kind-111 last interaction-choice-control-income-frequency-kind-7'
  end

  def self.prizes_and_awards_checkbox
    'input[class="other-income-checkbox-prizes_and_awards interaction-choice-control-value-other-income-kind"]'
  end

  def self.prizes_awards_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-113 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.prizes_awards_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-116 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.prizes_awards_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-119 last interaction-choice-control-income-frequency-kind-7"]'
  end

  def self.taxable_scholorship_payments_checkbox
    'input[class="other-income-checkbox-scholorship_payments interaction-choice-control-value-other-income-kind"]'
  end

  def self.taxable_scholorship_select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-121 interaction-choice-control-income-frequency-kind-1"]'
  end

  def self.taxable_scholorship_select_monthly
    'li[class="interaction-choice-control-income-frequency-kind-124 interaction-choice-control-income-frequency-kind-4"]'
  end

  def self.taxable_scholorship_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-127 last interaction-choice-control-income-frequency-kind-7"]'
  end
end
