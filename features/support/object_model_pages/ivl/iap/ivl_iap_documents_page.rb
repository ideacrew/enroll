# frozen_string_literal: true

#insured/consumer_role/upload_ridp_document
class IvlIapDocumentsPage

  def self.confirm_btn
    'input[class="btn btn-primary interaction-click-control-confirm"]'
  end

  def self.upload_identity_documents_btn
    '#upload_identity'
  end

  def self.upload_application_documents_btn
    '#upload_application'
  end

  def self.continue_application_btn
    'a[class="btn btn-primary  btn-small interaction-click-control-override-identity-verification no-op  interaction-click-control-continue-application"]'
  end

  def self.documents_faq_btn
    'a[class="btn btn-default btn-small pull-right interaction-click-control-documents-faq"]'
  end
end