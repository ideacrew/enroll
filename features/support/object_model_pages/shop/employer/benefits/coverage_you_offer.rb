# frozen_string_literal: true

class CoverageYouOffer

  include RSpec::Matchers
  include Capybara::DSL

  def claim_quote_btn
    '//a[contains(@class, "interaction-click-control-claim-quote")]'
  end

  def add_plan_year_btn
    '//a[@id="AddPlanYearBtn"]'
  end
end