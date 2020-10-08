# frozen_string_literal: true

class AddNewEmployee

  include RSpec::Matchers
  include Capybara::DSL

  def first_name
    '//input[@id="census_employee_first_name"]'
  end

  def middle_name
    '//input[@id="census_employee_middle_name"]'
  end

  def last_name
    '//input[@id="census_employee_last_name"]'
  end

  def suffix_dropdown
    '(//div[@class="selectric"]//span)[1]'
  end

  def date_of_birth
    '//input[@id="jq_datepicker_ignore_census_employee_dob"]'
  end

  def ssn
    '//input[@id="census_employee_ssn"]'
  end

  def male_radiobtn
    '(//span[@class="n-radio"])[1]'
  end

  def female_radiobtn
    '(//span[@class="n-radio"])[2]'
  end

  def hire_date
    '//input[@id="jq_datepicker_ignore_census_employee_hired_on"]'
  end

  def is_owner_checkbox
    '//input[@id="census_employee_is_business_owner"]'
  end

  def benefit_package_dropdown
    '(//div[@class="selectric"]//span)[2]'
  end

  def address_line_one
    '//input[@id="census_employee_address_attributes_address_1"]'
  end

  def address_line_two
    '//input[@id="census_employee_address_attributes_address_2"]'
  end

  def city
    '//input[@id="census_employee_address_attributes_city"]'
  end

  def state_dropdown
    '(//div[@class="selectric"]//span)[3]'
  end

  def zip
    '//input[@id="census_employee_address_attributes_zip"]'
  end

  def kind_dropdown
    '(//div[@class="selectric"]//span)[4]'
  end

  def email
    '//input[@id="census_employee_email_attributes_address"]'
  end

  def add_dependent_btn
    '//a[@class="add_fields btn btn-default btn-sm interaction-click-control-add-dependent"]'
  end

  def first_name_dependent
    '//input[@id="census_employee_census_dependents_attributes_1602101094050_first_name"]'
  end

  def middle_name_dependent
    '//input[@id="census_employee_census_dependents_attributes_1602101094050_middle_name"]'
  end

  def last_name_dependent
    '//input[@id="census_employee_census_dependents_attributes_1602101094050_last_name"]'
  end

  def ssn_dependent
    '//input[@id="census_employee_census_dependents_attributes_1602101094050_ssn"]'
  end

  def trash_icon
    '//a[@class="remove_fields close-2"]'
  end

  def dob_dependent
    '//input[@id="jq_datepicker_ignore_census_employee_census_dependents_attributes_1602101094050_dob"]'
  end

  def male_dependent_radiobtn
    '(//span[@class="n-radio"])[3]'
  end

  def female_dependent_radiobtn
    '(//span[@class="n-radio"])[4]'
  end

  def relationship_dropdown
    '(//span[@class="label"])[5]'
  end

  def cancel_btn
    '//a[@class="btn btn-default btn-lg return_to_employee_roster interaction-click-control-cancel"]'
  end

  def create_employee_btn
    '//button[@class="btn btn-primary btn-lg interaction-click-control-create-employee"]'
  end

end