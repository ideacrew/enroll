# frozen_string_literal: true

class BenefitPackageSetUp

  include RSpec::Matchers
  include Capybara::DSL
      
  def my_benefit_package
    '//input[@id="benefitPackageTitle"]'
  end

  def my_description
    '//input[@id="benefit_package_description"]'
  end

  def first_of_the_month_dropdown
    '//span[@class="label"]'
  end

  def by_carrier_btn
    '//a[@class="interaction-click-control-by-carrier"]'
  end

  def aetna_radiobtn
    '(//span[@class="checkmark"])[1]'
  end

  def carefirst_radiobtn
    '(//span[@class="checkmark"])[2]'
  end

  def kaiser_radiobtn
    '(//span[@class="checkmark"])[3]'
  end

  def uhc_radiobtn
    '(//span[@class="checkmark"])[4]'
  end

  def by_metal_level_btn
    ''
  end

  def single_plan_btn
    ''
  end

  def c
    ''
  end

  def c
    ''
  end
end