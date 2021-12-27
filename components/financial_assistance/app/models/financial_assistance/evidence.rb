# frozen_string_literal: true

module FinancialAssistance
  #Evidences for an applicant to detrmine its status
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include ::EventSource::Command

    DUE_DATE_STATES = %w[review outstanding].freeze

    VERIFY_REASONS = EnrollRegistry[:verification_reasons].item
    #add them to registry
    REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person", "Expired", "Too old"].freeze

    FDSH_EVENTS = {
      :non_esi_mec => 'fdsh.evidences.esi_determination_requested',
      :esi_mec => 'fdsh.evidences.non_esi_determination_requested',
      :income => 'fti.evidences.ifsv_determination_requested',
      :local_mec => "iap.mec_check.mec_check_requested"
    }.freeze

    # embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'

    embedded_in :evidencable, polymorphic: true

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
    default_scope ->{ exists(key: true) }


    def request_determination
      application = self.applicant.application
      payload = construct_payload(application)
      event(FDSH_EVENTS[self.key], attributes: payload.to_h, headers: { correlation_id: application.id })
    end

    def construct_payload(application)
      cv3_application = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).value!
      AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application).value!
    end

    def extend_due_on(date = (TimeKeeper.datetime_of_record + 30.days))
      self.due_on = date
    end

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