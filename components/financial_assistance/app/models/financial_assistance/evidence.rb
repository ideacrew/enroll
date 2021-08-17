# frozen_string_literal: true

module FinancialAssistance
  #Evidences for an applicant to detrmine his status
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :eligibility_status, type: String
    field :due_on, type: Date
    field :external_service, type: String
    field :updated_by, type: String

    embeds_one :verification_status, class_name: "::FinancialAssistance::VerificationStatus"
    embeds_many :verification_history, class_name: "::FinancialAssistance::VerificationHistory"
    embeds_many :eligibility_results, class_name: "::FinancialAssistance::EligibilityResult"

    scope :by_name, ->(type_name) { where(:key => type_name) }


    def type_unverified?
      !type_verified?
    end

    def type_verified?
      ["verified", "attested"].include? eligibility_status
    end
  end
end