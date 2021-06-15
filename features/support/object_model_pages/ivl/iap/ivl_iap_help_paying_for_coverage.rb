# frozen_string_literal: true

#insured/consumer_role/help_paying_coverage
class IvlIapHelpPayingForCoverage

  def self.yes_radiobtn
    'label[for="radio1"] span'
  end

  def self.no_radiobtn
    'label[for="radio2"] span'
  end

  def self.not_sure_is_applying_for_assistance
    'a[href="#is_applying_for_assistance"]'
  end

  def self.continue_btn
    '#btn-continue'
  end

  def self.your_application_for_premium_reductions_text
    'Your Application for Premium Reductions'
  end
end