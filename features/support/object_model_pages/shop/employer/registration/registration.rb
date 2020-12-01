# frozen_string_literal: true

class Registration

  include RSpec::Matchers
  include Capybara::DSL
  
  def first_name
    '//input[@id="agency_staff_roles_attributes_0_first_name"]'
  end

  def last_name
    '//input[@id="agency_staff_roles_attributes_0_last_name"]'
  end

  def date_of_birth
    '//input[@id="inputDOB"]'
  end

  def email
    '//input[@id="agency_staff_roles_attributes_0_email"]'
  end

  def area_code_personal_information
    '//input[@id="agency_staff_roles_attributes_0_area_code"]'
  end

  def number_personal_information
    '(//input[@id="inputNumber"])[1]'
  end

  def legal_name
    '//input[@id="agency_organization_legal_name"]'
  end

  def dba
    '//input[@id="agency_organization_dba"]'
  end

  def fein
    '//input[@id="agency_organization_fein"]'
  end

  def kind
    '//select[@id="agency_organization_entity_kind"]'
  end

  def address
    '//input[@id="inputAddress1"]'
  end

  def kind_office_location_dropdown
    '//select[@id="kindSelect"]'
  end

  def address_two
    '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2"]'
  end

  def city
    '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city"]'
  end

  def state_dropdown
    '//select[@id="inputState"]'
  end

  def zip
    '//input[@id="inputZip"]'
  end

  def area_code_office_location
    '//input[@id="inputAreacode"]'
  end

  def number_office_location
    '(//input[@id="inputNumber"])[2]'
  end

  def add_office_location_btn
    '//a[@id="addOfficeLocation"]'
  end

  def contact_method_dropdown
    '//select[@id="agency_organization_profile_attributes_contact_method"]'
  end

  def confirm_btn
    '//input[@class="btn btn-primary pull-right mt-2"]'
  end

end