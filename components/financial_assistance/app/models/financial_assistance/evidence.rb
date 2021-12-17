# frozen_string_literal: true

module FinancialAssistance
  #Evidences for an applicant to detrmine his status
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps

    DUE_DATE_STATES = %w[review outstanding].freeze

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :eligibility_status, type: String
    field :update_reason, type: String
    field :rejected, type: Boolean
    field :due_on, type: Date
    field :external_service, type: String
    field :updated_by, type: String

    embeds_one :verification_status, class_name: "::FinancialAssistance::VerificationStatus"
    embeds_many :verification_history, class_name: "::FinancialAssistance::VerificationHistory"
    embeds_many :eligibility_results, class_name: "::FinancialAssistance::EligibilityResult"

    embeds_many :documents, as: :documentable do
      def uploaded
        @target.select(&:identifier)
      end
    end

    scope :by_name, ->(type_name) { where(:key => type_name) }

    validates :title, presence: true
    validates :key, presence: true

    def type_unverified?
      !type_verified?
    end

    def type_verified?
      ["verified", "attested"].include? eligibility_status
    end

    def verif_due_date
      due_on || TimeKeeper.date_of_record + 95.days
    end

    def add_verification_history(params)
      verification_history << FinancialAssistance::VerificationHistory.new(params)
    end
  end
end