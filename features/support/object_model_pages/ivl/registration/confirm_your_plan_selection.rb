# frozen_string_literal: true

class ChoosePlan

  include RSpec::Matchers
  include Capybara::DSL
      
  def i_agree_checkbox
    '//input[@id="terms_check_thank_you"]'
  end

  def first_name
    '//input[@id="first_name_thank_you"]'
  end

  def last_name
    '//input[@id="last_name_thank_you"]'
  end

  def confirm_btn
    '//a[@id="btn-continue"]'
  end

  def previous_link
    '//a[@class="back interaction-click-control-previous"]'
  end
end