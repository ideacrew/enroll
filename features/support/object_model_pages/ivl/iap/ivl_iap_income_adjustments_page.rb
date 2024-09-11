# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/deductions
class IvlIapIncomeAdjustmentsPage

  def self.income_adjustments_yes_radiobtn
    '#has_deductions_true' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.income_adjustments_no_radiobtn
    '#has_deductions_false' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.not_sure_has_deductions
    'a[href="#has_deductions"]'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end

  def self.save_and_exit_link
    'a[class="interaction-click-control-save---exit"]'
  end

  def self.alimony_paid_checkbox
    'input[class="deduction-checkbox-alimony_paid interaction-choice-control-value-deduction-kind"]'
  end

  def self.amount
    'deduction[amount]'
  end

  def self.how_often_dropdown
    'div[class="selectric interaction-choice-control-deduction-frequency-kind"]'
  end

  def self.alimony_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.alimony_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.from
    'deduction[start_on]'
  end

  def self.calendar
    '#ui-datepicker-div'
  end

  def self.cancel_btn
    'a[class="btn btn-default deduction-cancel interaction-click-control-cancel"]'
  end

  def self.save_btn
    'input[class="btn btn-danger interaction-click-control-save"]'
  end

  def self.deductible_part_of_self_employment_checkbox
    'input[class="deduction-checkbox-deductable_part_of_self_employment_taxes interaction-choice-control-value-deduction-kind"]'
  end

  def self.deductible_self_emplopyment_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-9 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.deductible_self_emplopyment_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-12 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.domestic_production_activities_checkbox
    'input[class="deduction-checkbox-domestic_production_activities interaction-choice-control-value-deduction-kind"]'
  end

  def self.domestic_production_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-17 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.domestic_production_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-20 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.penalty_on_early_withdrawal_of_savings_checkbox
    'input[class="deduction-checkbox-penalty_on_early_withdrawal_of_savings interaction-choice-control-value-deduction-kind"]'
  end

  def self.penalty_withdrawal_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-25 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.pension_retirement_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-28 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.educator_expenses_checkbox
    'input[class="deduction-checkbox-educator_expenses interaction-choice-control-value-deduction-kind"]'
  end

  def self.educator_expenses_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-33 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.educator_expenses_select_monthly
    'interaction-choice-control-deduction-frequency-kind-36 interaction-choice-control-deduction-frequency-kind-4'
  end

  def self.self_employment_sep_simple_and_qualified_plans_checkbox
    'input[class="deduction-checkbox-self_employment_sep_simple_and_qualified_plans interaction-choice-control-value-deduction-kind"]'
  end

  def self.self_employment_sep_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-41 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.self_employment_sep_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-44 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.self_employed_health_insurance_checkbox
    'input[class="deduction-checkbox-self_employed_health_insurance interaction-choice-control-value-deduction-kind"]'
  end

  def self.self_employed_health_insurance_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-49 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.self_employed_health_insurance_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-52 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.student_loan_interest_checkbox
    'input[class="deduction-checkbox-student_loan_interest interaction-choice-control-value-deduction-kind"]'
  end

  def self.student_loans_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-57 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.student_loans_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-60 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.moving_expenses_checkbox
    'input[class="deduction-checkbox-moving_expenses interaction-choice-control-value-deduction-kind"]'
  end

  def self.moving_expenses_how_often_dropdown
    '.new-deduction-form.moving_expenses span.label'
  end

  def self.moving_expenses_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-65 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.moving_expenses_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-68 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.moving_expenses_select_yearly
    '.new-deduction-form.moving_expenses li.interaction-choice-control-deduction-frequency-kind-7'
  end

  def self.income_adjustments_save_btn
    '[data-cuke="income-adjustments-save-button"]'
  end

  def self.health_savings_account_checkbox
    'input[class="deduction-checkbox-health_savings_account interaction-choice-control-value-deduction-kind"]'
  end

  def self.health_savings_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-73 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.health_savings_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-76 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.ira_deduction_checkbox
    'input[class="deduction-checkbox-ira_deduction interaction-choice-control-value-deduction-kind"]'
  end

  def self.ira_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-81 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.ira_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-84 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.reservists_performing_artists_and_fee_basis_government_official_expenses_checkbox
    'input[class="deduction-checkbox-reservists_performing_artists_and_fee_basis_government_official_expenses interaction-choice-control-value-deduction-kind"]'
  end

  def self.reservists_performing_artists_and_fee_basis_government_official_expenses_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-89 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.reservists_performing_artists_and_fee_basis_government_official_expenses_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-92 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.tuition_and_fees_checkbox
    'input[class="deduction-checkbox-tuition_and_fees interaction-choice-control-value-deduction-kind"]'
  end

  def self.tuition_and_fees_select_bi_weekly
    'li[class="interaction-choice-control-deduction-frequency-kind-97 interaction-choice-control-deduction-frequency-kind-1"]'
  end

  def self.taxable_income_select_monthly
    'li[class="interaction-choice-control-deduction-frequency-kind-100 interaction-choice-control-deduction-frequency-kind-4"]'
  end

  def self.health_savings_account
    '.health_savings_account'
  end

  def self.health_savings_account_glossary_link
    '[data-title="Health savings account"]'
  end

  def self.alimony_paid
    '.alimony_paid'
  end

  def self.alimony_paid_glossary_link
    '.alimony_paid span'
  end
end
