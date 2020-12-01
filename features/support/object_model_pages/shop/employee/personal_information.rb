# frozen_string_literal: true

class PersonalInformation

  include RSpec::Matchers
  include Capybara::DSL
  
  def first_name
    '//input[@id="person_first_name"]'
  end
  
  def middle_name
    '//input[@id="person_middle_name"]'
  end
  
  def last_name
    '//input[@id="person_last_name"]'
  end
  
  def suffix_dropdown
    '//div[@class="selectric"]'
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
    '//button[@id="btn-continue"]'
  end

end