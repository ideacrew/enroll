# frozen_string_literal: true

class HouseholdInfo

  include RSpec::Matchers
  include Capybara::DSL

  def add_member_btn
    '(//a[text()="Add Member"])[2]'
  end

  def dependent_first_name
    '//input[@id="dependent_first_name"]'
  end

  def dependent_middle_name
    '//input[@id="dependent_middle_name"]'
  end

  def dependent_last_name
    '//input[@id="dependent_last_name"]'
  end

  def dependent_dob
    '//input[@id="family_member_dob_"]'
  end

  def dependent_ssn
    '//input[@id="dependent_ssn"]'
  end

  def dependent_no_ssn_checkbox
    '//input[@id="dependent_no_ssn"]'
  end

  def male_radiobtn
    '//label[@for="radio_male"]//span'
  end

  def female_radiobtn
    '//label[@for="radio_female"]//span'
  end

  def dependent_relationship_dropdown
    '(//span[@class="label"])[1]'
  end

  def applying_coverage_yes_radiobtn
    '//label[@for="is_applying_coverage_true"]//span'
  end

  def applying_coverage_no_radiobtn
    '//label[@for="is_applying_coverage_false"]//span'
  end

  def us_citizen_or_national_yes_radiobtn
    '//label[@for="dependent_us_citizen_true"]/span'
  end

  def us_citizen_or_national_no_radiobtn
    '//label[@for="dependent_us_citizen_false"]/span'
  end

  def naturalized_citizen_yes_radiobtn
    '//label[@for="dependent_naturalized_citizen_true"]/span'
  end

  def naturalized_citizen_no_radiobtn
    '//label[@for="dependent_naturalized_citizen_false"]/span'
  end

  def naturalized_citizen_select_doc_dropdown
    '(//span[text()="Select document type"])[2]'
  end

  def immigration_status_yes_radiobtn
    '//label[@for="dependent_eligible_immigration_status_true"]/span'
  end

  def immigration_status_no_radiobtn
    '//label[@for="dependent_eligible_immigration_status_false"]/span'
  end

  def immigration_status_select_doc_dropdown
    '(//span[text()="Select document type"])[1]'
  end

  def american_or_alaskan_native_yes_radiobtn
    '//label[@for="indian_tribe_member_yes"]/span'
  end

  def american_or_alaskan_native_no_radiobtn
    '//label[@for="indian_tribe_member_no"]/span'
  end

  def incarcerated_yes_radiobtn
    '//label[@for="radio_incarcerated_yes"]/span'
  end

  def incarcerated_no_radiobtn
    '//label[@for="radio_incarcerated_no"]/span'
  end

  def lives_with_prim_subs_checkbox
    '//input[@id="dependent_same_with_primary"]'
  end

  def confirm_member_btn
    '//span[@class="btn btn-primary btn-br pull-right mz"]'
  end

  def cancel_btn
    '//a[@class="btn btn-default remove-new-employee-dependent"]'
  end

  def edit_icon
    '//i[@class="fa fa-edit"]'
  end

  def continue_btn
    '//a[@id="btn-continue"]'
  end

  def previous_link
    '//a[@class="back interaction-click-control-previous"]'
  end

  def save_and_exit_link
    '//a[@class="interaction-click-control-save---exit"]'
  end

  def help_me_sign_up_btn
    '//div[@class="btn btn-default btn-block help-me-sign-up"]'
  end
end