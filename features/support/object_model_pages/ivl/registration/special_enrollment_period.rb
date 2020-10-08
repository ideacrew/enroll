# frozen_string_literal: true

class SpecialEnrollmentPeriod

  include RSpec::Matchers
  include Capybara::DSL
  
  def covid_link
    '//a[@class="qle-menu-item interaction-click-control-covid-19"]'
  end
  
  def had_a_baby_link
    '//a[@class="qle-menu-item interaction-click-control-had-a-baby"]'
  end
  
  def adopted_a_child_link
    '//a[@class="qle-menu-item interaction-click-control-adopted-a-child"]'
  end
  
  def lost_or_will_lose_health_insurance_link
    '//a[@class="qle-menu-item interaction-click-control-lost-or-will-soon-lose-other-health-insurance"]'
  end
  
  def married_link
    '//a[@class="qle-menu-item interaction-click-control-married"]'
  end
  
  def backward_arrow
    '//i[@class="fa fa-angle-left left fa-2x"]'
  end

  def forward_arrow
    '//i[@class="fa fa-angle-right right fa-2x"]'
  end

  def none_apply_checkbox
    '//input[@id="no_qle_checkbox"]'
  end

  def qle_date
    '//input[@id="qle_date"]'
  end

  def continue_qle_btn
    '//a[@id="qle_submit"]'
  end

  def outside_qle_close_btn
    '//button[@class="btn btn-default interaction-click-control-close"]'
  end

  def outside_qle_back_to_my_acct_btn
    '//a[@class="btn btn-primary interaction-click-control-back-to-my-account"]'
  end

  def select_effective_date_dropdown
    '//select[@id="effective_on_kind"]'
  end

  def effective_date_continue_btn
    '//input[@class="btn btn-primary interaction-click-control-continue"]'
  end

end