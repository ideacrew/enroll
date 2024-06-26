# frozen_string_literal: true

#insured/consumer_role/help_paying_coverage
class IvlIapHelpPayingForCoverage

  def self.yes_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-choice-control-value-radio1'
    else
    'label[for="radio1"] span'
    end
  end

  def self.no_radiobtn
    'label[for="radio2"] span'
  end

  def self.not_sure_is_applying_for_assistance
    'a[href="#is_applying_for_assistance"]'
  end

  def self.continue_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-click-control-continue-to-next-step'
     else
      '#btn-continue'
     end
  end

  def self.your_application_for_premium_reductions_text
    'Your Application for Premium Reductions'
  end
end