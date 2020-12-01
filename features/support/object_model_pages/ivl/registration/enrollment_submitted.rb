# frozen_string_literal: true

class EnrollmentSubmitted

  include RSpec::Matchers
  include Capybara::DSL
    
  def how_to_pay_btn
      '//span[@class="btn btn-default"]'
  end

  def print_btn
    '//a[@id="btnPrint"]'
  end

  def go_to_my_acct_btn
    '//a[@id="btn-continue"]'
  end
end