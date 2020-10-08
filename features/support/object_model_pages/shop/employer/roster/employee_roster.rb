# frozen_string_literal: true

class EmployeeRoster

  include RSpec::Matchers
  include Capybara::DSL
    
  def add_new_employee_btn
    '//a[contains(@class, "interaction-click-control-add-new-employee")]'
  end

  def upload_employee_roster_btn
    '//a[contains(@class, "interaction-click-control-upload-employee-roster")]'
  end

  def choose_file_btn
    '//input[@id="file"]'
  end

  def select_file_to_upload_btn
    '//label[@class="select btn btn-primary"]'
  end

  def upload_btn
    '//input[@class="btn btn-primary interaction-click-control-upload"]'
  end
  
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

  def download_employee_roster_btn
    '//a[@class="btn btn-default interaction-click-control-download-employee-roster"]'
  end

  def active_only_btn
    '//div[@id="Tab:active_alone"]'
  end

  def active_and_cobra_btn
    '//div[@id="Tab:active"]'
  end

  def cobra_only_btn
    '//div[@id="Tab:by_cobra"]'
  end

  def terminated_btn
    '//div[@id="Tab:terminated"]'
  end

  def all_btn
    '//div[@id="Tab:all"]'
  end

  def search
    '//input[@class="form-control input-sm"]'
  end

  def actions_btn
    '//button[@id="dropdown_for_census_employeeid_5f7e22391548433ba5868418"]'
  end

end  