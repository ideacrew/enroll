# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/incomes
class IvlIapJobIncomeInformationPage

  def self.has_job_income_yes_radiobtn
    'has_job_income_true'
  end

  def self.has_job_income_no_radiobtn
    'has_job_income_false'
  end

  def self.not_sure_has_job_income_link
    'a[href="#has_job_income"]'
  end

  def self.employer_name
    'EMPLOYER NAME *'
  end

  def self.income_amount
    'income_amount'
  end

  def self.income_how_often_dropdown
    'div[class="selectric-wrapper selectric-interaction-choice-control-income-frequency-kind"] span'
  end

  def self.select_bi_weekly
    'li[class="interaction-choice-control-income-frequency-kind-1 interaction-choice-control-income-employer-address-state-1"]'
  end

  def self.select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-7 last interaction-choice-control-income-employer-address-state-7"]'
  end

  def self.income_from
    'income[start_on]'
  end

  def self.income_to
    'income[end_on]'
  end

  def self.income_employer_address_1
    'income_employer_address_address_1'
  end

  def self.income_employer_city
    'income_employer_address_city'
  end

  def self.income_employer_state_dropdown
    'div[class="selectric-wrapper selectric-interaction-choice-control-income-employer-address-state"]'
  end

  def self.select_va_state
    'li[class="interaction-choice-control-income-employer-address-state-46 interaction-choice-control-income-frequency-kind-46"]'
  end

  def self.income_employer_zip
    'income[employer_address][zip]'
  end

  def self.income_employer_phone_number
    'income[employer_phone][full_phone_number]'
  end

  def self.income_save_btn
    'input[class="btn btn-danger interaction-click-control-save"]'
  end

  def self.income_cancel_btn
    'a[class="btn btn-default income-cancel interaction-click-control-cancel"]'
  end

  def self.income_employer_edit_btn
    'a[class="income-edit edit-pr"] i'
  end

  def self.income_employer_delete_btn
    'a[class="income-delete"]'
  end

  def self.has_self_employee_income_yes_radiobtn
    'has_self_employment_income_true'
  end

  def self.has_self_employee_income_no_radiobtn
    'has_self_employment_income_false'
  end

  def self.self_employee_income_amount
    'income_amount'
  end

  def self.self_employee_how_often_dropdown
    'div[class="selectric interaction-choice-control-income-frequency-kind interaction-choice-control-income-employer-address-state"]'
  end

  def self.self_employee_income_from
    'income[start_on]'
  end

  def self.self_employee_income_to
    'income[end_on]'
  end

  def self.self_employee_select_yearly
    'li[class="interaction-choice-control-income-frequency-kind-15 last interaction-choice-control-income-frequency-kind-7 interaction-choice-control-income-employer-address-state-7"]'
  end

  def self.not_sure_has_self_employment_income_link
    'a[href="#has_self_employment_income"]'
  end

  def self.self_employee_cancel_btn
    'a[class="btn btn-default income-cancel interaction-click-control-cancel"]'
  end

  def self.self_self_employee_save_btn
    'input[class="btn btn-danger interaction-click-control-save"]'
  end

  def self.self_employee_edit_btn
    'div[class="col-md-1 form-group-lg no-pd class-fa-household fa-adjustment"] i[class="fa fa-pencil fa-lg"]'
  end

  def self.self_employee_delte_btn
    'a[class="self-employed-income-delete"]'
  end

  def self.self_employee_continue_and_remove_btn
    'button[class="btn btn-primary modal-continue-button interaction-click-control-continue---remove"]'
  end

  def self.self_employee_do_not_remove_btn
    'button[class="btn btn-default modal-cancel-button interaction-click-control-don\'t-remove"]'
  end

  def self.continue_btn
    'a[id="btn-continue"]'
  end
end