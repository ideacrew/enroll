# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/incomes
class IvlIapJobIncomeInformationPage

  def self.has_job_income_yes_radiobtn
    'has_job_income_true'
  end

  def self.has_job_income_no_radiobtn
    '#has_job_income_false'
  end

  def self.not_sure_has_job_income_link
    'a[href="#has_job_income"]'
  end

  def self.employer_name
    'income[employer_name]'
  end

  def self.income_amount
    'income_amount'
  end

  def self.income_how_often_dropdown
    'div[class="fa-frequency-kind"] span.label'
  end

  def self.select_bi_weekly
    '.fa-frequency-kind li[data-index="1"]'
  end

  def self.select_yearly
    '.fa-frequency-kind li[data-index="7"]'
  end

  def self.income_from
    'income[start_on]'
  end

  def self.income_to
    'income[end_on]'
  end

  def self.income_employer_address_1
    'income[employer_address][address_1]'
  end

  def self.calendar
    'table[class="ui-datepicker-calendar"]'
  end

  def self.income_employer_address_2
    'income[employer_address][address_2]'
  end

  def self.income_employer_city
    'income[employer_address][city]'
  end

  def self.income_employer_state_dropdown
    'div[class="selectric-wrapper selectric-interaction-choice-control-income-employer-address-state"]'
  end

  def self.select_dc
    '.employer-state li[data-index="9"]'
  end

  def self.select_va_state
    'li[class="interaction-choice-control-income-employer-address-state-47 interaction-choice-control-income-frequency-kind-47"]'
  end

  def self.income_employer_zip
    'income[employer_address][zip]'
  end

  def self.income_employer_phone_number
    'income[employer_phone][full_phone_number]'
  end

  def self.income_save_btn
    '[data-cuke="job-income-save-button"]'
  end

  def self.add_another_job_income
    '.interaction-click-control-add-another-job-income'
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
    '#has_self_employment_income_false'
  end

  def self.self_employee_income_amount
    'income_amount'
  end

  def self.self_employee_how_often_dropdown
    '[data-cuke="self-employed-income-how-often-dropdown"]'
  end

  def self.self_employed_yearly
    '#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7'
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
    '[data-cuke="self-employed-income-save-button"]'
  end

  def self.self_add_another_self_employment
    '.interaction-click-control-add-another--self-employed-income'
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
    '.interaction-click-control-continue'
  end

  def self.start_date_warning
    '[data-cuke="start-date-warning"]'
  end

  def self.end_date_warning
    '[data-cuke="end-date-warning"]'
  end
end
