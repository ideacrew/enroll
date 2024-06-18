# frozen_string_literal: true

#insured/consumer_role/ridp_agreement
class IvlAuthorizationAndConsent

  def self.i_agree_radiobtn
    'label[for="agreement_agree"] span'
  end

  def self.i_disagree_radiobtn
    'label[for="agreement_disagree"] span'
  end

  def self.continue_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-click-control-continue-to-next-step'
    else 
      '.interaction-click-control-continue'
    end
  end

  def self.previous_link
    '.interaction-click-control-previous'
  end

  def self.save_and_exit_link
    '.interaction-click-control-save---exit'
  end

  def self.help_me_sign_up_btn
    '.help-me-sign-up'
  end

  def self.authorization_and_consent_text
    'Authorization and Consent'
  end
end

