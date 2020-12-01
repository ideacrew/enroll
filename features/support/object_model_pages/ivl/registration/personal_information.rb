# frozen_string_literal: true

class PersonalInformation

  def self.first_name
    'person[first_name]'
  end

  def self.middle_name
    'person[middle_name]'
  end

  def self.last_name
    'person[last_name]'
  end

  def self.suffix_dropdown
    'selectric-wrapper'
  end

  def applying_coverage_yes_radiobtn
    '//label[@for="is_applying_coverage_true"]//span'
  end

  def applying_coverage_no_radiobtn
    '//label[@for="is_applying_coverage_false"]//span'
  end

  def dob
    '//input[@id="jq_datepicker_ignore_person_dob"]'
  end

  def social_security
    '//input[@id="person_ssn"]'
  end

  def i_dont_have_an_ssn_checkbox
    '//input[@id="person_no_ssn"]'
  end

  def male_radiobtn
    '//span[text()="MALE"]'
  end

  def female_radiobtn
    '//span[text()="FEMALE"]'
  end

  def continue_btn
    '//span[text()="CONTINUE"]'
  end

  def thank_you_confirmation_message
    '//div[@class="alert alert-success alert-dismissible"]'
  end

  def previous_link
    '//a[@class="back interaction-click-control-previous"]'
  end

  def us_citizen_or_national_yes_radiobtn
    '//label[@for="person_us_citizen_true"]/span'
  end

  def us_citizen_or_national_no_radiobtn
    '//label[@for="person_us_citizen_false"]/span'
  end

  def naturalized_citizen_yes_radiobtn
    '//label[@for="person_naturalized_citizen_true"]/span'
  end

  def naturalized_citizen_no_radiobtn
    '//label[@for="person_naturalized_citizen_false"]/span'
  end

  def naturalized_citizen_select_doc_dropdown
    '(//span[text()="Select document type"])[2]'
  end

  def immigration_status_yes_radiobtn
    '//label[@for="person_eligible_immigration_status_true"]/span'
  end

  def immigration_status_no_radiobtn
    '//label[@for="person_eligible_immigration_status_false"]/span'
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

  def no_dc_address_checkbox
    '//input[@id="no_dc_address"]'
  end

  def address_line_one
    '//input[@id="person_addresses_attributes_0_address_1"]'
  end

  def address_line_two
    '//input[@id="person_addresses_attributes_0_address_2"]'
  end

  def city
    '//input[@id="person_addresses_attributes_0_city"]'
  end

  def select_state_dropdown
    '//span[text()="SELECT STATE *"]'
  end

  def zip
    '//input[@id="person_addresses_attributes_0_zip"]'
  end

  def add_mailing_address_btn
    '//span[text()="Add Mailing Address"]'
  end

  def mailing_address_line_one
    '//input[@id="person_addresses_attributes_1_address_1"]'
  end

  def mailing_address_line_two
    '//input[@id="person_addresses_attributes_1_address_2"]'
  end

  def mailing_address_city
    '//input[@id="person_addresses_attributes_1_city"]'
  end

  def mailing_address_state_dropdown
    '//span[text()="SELECT STATE "]'
  end

  def mailing_address_zip
    '//input[@id="person_addresses_attributes_1_zip"]'
  end

  def remove_mailing_address_btn
    '//span[text()="Remove Mailing Address"]'
  end

  def home_phone
    '//input[@id="person_phones_attributes_0_full_phone_number"]'
  end

  def mobile_phone
    '//input[@id="person_phones_attributes_1_full_phone_number"]'
  end

  def home_email_address
    '//input[@id="person_emails_attributes_0_address"]'
  end

  def work_email_address
    '//input[@id="person_emails_attributes_1_address"]'
  end

  def contact_method_dropdown
    '//span[text()="Both electronic and paper communications"]'
  end

  def language_preference_dropdown
    '//span[text()="English"]'
  end

  def help_me_sign_up_btn
    '//div[@class="btn btn-default btn-block help-me-sign-up"]'
  end

  def save_and_exit_link
    '//a[@class="interaction-click-control-save---exit"]'
  end
end