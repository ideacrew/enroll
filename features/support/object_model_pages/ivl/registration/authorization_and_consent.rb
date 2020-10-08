# frozen_string_literal: true

class AuthorizationAndConsent

  include RSpec::Matchers
  include Capybara::DSL

  def i_agree_radiobtn
    '//span[text()="I agree"]'
  end

  def i_disagree_radiobtn
    '//span[text()="I disagree"]'
  end

  def continue_btn
    '//a[@id="btn-continue"]'
  end

  def previous_link
    '//a[@class="back interaction-click-control-previous"]'
  end

  def help_me_sign_up_btn
    '//div[@class="btn btn-default btn-block help-me-sign-up"]'
  end

  def save_and_exit_link
    '//a[@class="interaction-click-control-save---exit"]'
  end
end

