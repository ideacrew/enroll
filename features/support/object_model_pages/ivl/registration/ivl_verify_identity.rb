# frozen_string_literal: true

#insured/interactive_identity_verifications/new
#insured/interactive_identity_verifications/failed_validation?step=questions&verification_transaction_id
class IvlVerifyIdentity

  def self.verify_identity_text
    'Verify Identity'
  end

  def self.pick_answer_a
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '#interactive_verification_questions_attributes_0_response_id_a'
    else
    'label[for="interactive_verification_questions_attributes_0_response_id_a"] span'
    end
  end

  def self.pick_answer_b
    if EnrollRegistry[:bs4_consumer_flow].enabled?
    '#interactive_verification_questions_attributes_0_response_id_b'
    else
    'label[for="interactive_verification_questions_attributes_0_response_id_b"] span'
    end
  end

  def self.pick_answer_c
    if EnrollRegistry[:bs4_consumer_flow].enabled?
    '#interactive_verification_questions_attributes_1_response_id_c'
    else
    'label[for="interactive_verification_questions_attributes_1_response_id_c"] span'
    end
  end

  def self.pick_answer_d
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '#interactive_verification_questions_attributes_1_response_id_d'
    else
    'label[for="interactive_verification_questions_attributes_1_response_id_d"] span'
    end
  end

  def self.submit_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
    '.interaction-click-control-submit'
    else
    'input[value="Submit"]'
    end
  end

  def self.continue_application_btn
     if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-click-control-continue-to-next-step'
     else
      '.interaction-click-control-continue'
     end
    end

  def self.upload_identity_docs_btn
    '#upload_identity'
  end

  def self.upload_application_docs_btn
    '#upload_application'
  end

  def self.select_file_to_upload_btn
    '#select_upload_identity'
  end

  def self.documents_faq_btn
    '.interaction-click-control-documents-faq'
  end

  def self.application_type_confirm_btn
    '.btn-primary.interaction-click-control-confirm'
  end

  def self.identity_actions_dropdown
    'div#Identity div.selectric span'
  end

  def self.identity_verify_btn
    'div#Identity div.selectric-scroll li[data-index="1"]'
  end

  def self.application_actions_dropdown
    'div#Application div.selectric'
  end

  def self.application_verify_btn
    'div#Application div.selectric-scroll li[data-index="1"]'
  end

  def self.select_reason_dropdown
    '.verification-update-reason'
  end

  def self.continue_btn
    '#btn-continue'
  end
end