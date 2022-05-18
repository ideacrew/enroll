# frozen_string_literal: true

#insured/families/verification?tab=verification
class IvlDocumentsPage

  def self.docs_we_accept_btn
    '.interaction-click-control-documents-we-accept'
  end

  def self.medicare_and_tax_credit_btn
    '.interaction-click-control-go-to-district-direct'
  end

  def self.income_evidence
    '#evidence_kind_income_evidence'
  end

  def self.local_mec_evidence_actions
    "#v-action-#{@applicant.id}-local-mec"
  end

  def self.view_history_option
    "//div[@class='selectric-scroll']/ul/li[contains(text(), 'View History')]"
  end
end
