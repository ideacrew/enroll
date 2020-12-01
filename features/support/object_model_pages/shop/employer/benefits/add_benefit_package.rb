# frozen_string_literal: true

class AddBenefitPackage

  include RSpec::Matchers
  include Capybara::DSL
      
  def select_start_on_dropdown
    '//div[@class="selectric"]//span'
  end

  def end_on
    '//input[@id="benefit_application_end_on"]'
  end

  def open_enrollment_start_date
    '//input[@id="benefit_application_open_enrollment_start_on"]'
  end

  def open_enrollment_end_date
    '//input[@id="benefit_application_open_enrollment_end_on"]'
  end

  def full_time_employees
    '//input[@id="fteEmployee"]'
  end

  def part_time_employees
    '//input[@id="pteEmployee"]'
  end

  def medicare_second_payers
    '//input[@id="medSecPayers"]'
  end

  def continue_btn
    '//input[@id="benefitContinueBtn"]'
  end
end