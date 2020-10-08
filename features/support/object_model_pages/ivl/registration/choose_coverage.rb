# frozen_string_literal: true

class ChooseCoverage

  include RSpec::Matchers
  include Capybara::DSL

  def consumer_checkbox
    '//input[@id="family_member_ids_0"]'
  end

  def dependent_checkbox
    '//input[@id="family_member_ids_1"]'
  end

  def individual_benefits_radiobtn
    '//input[@id="market_kind_individual"]//following-sibling::span'
  end

  def health_radiobtn
    '//input[@id="coverage_kind_health"]//following-sibling::span'
  end

  def dental_radiobtn
    '//input[@id="coverage_kind_dental"]//following-sibling::span'
  end

  def shop_for_new_plan_btn
    '//input[@name="commit"]'
  end

  def back_to_my_acct_btn
    '//a[@class="btn btn-default btn btn-lg interaction-click-control-back-to-my-account"]'
  end
end