# frozen_string_literal: true

module MagiMedicaid
  class Application

    include Mongoid::Document
    include Mongoid::Timestamps
    include Acapi::Notifiers
    require 'securerandom'

    before_create :set_hbx_id, :set_applicant_kind, :set_request_kind, :set_motivation_kind, :set_us_state, :set_is_ridp_verified
    validates :before_attestation_validity, presence: true, on: :before_attestation


    # TODO: Need enterprise ID assignment call for Assisted Application
    field :hbx_id, type: String

    ## Remove after data Cleanup ##
    field :external_id, type: String
    field :integrated_case_id, type: String
    ##
    field :family_id, type: BSON::ObjectId

    field :request_kind, type: String
    field :motivation_kind, type: String

    field :aasm_state, type: String, default: :draft
    field :submitted_at, type: DateTime
    field :effective_date, type: DateTime # Date they want coverage
    field :timeout_response_last_submitted_at, type: DateTime

    # The `assistance_year` of an application gets set during the submission of an application.
    # Use `FinancialAssistanceRegistry[:application_year].item.call.value!` method in the Family model incase you need `assistance_year`
    # when aplication is in a `draft state`.
    field :assistance_year, type: Integer

    field :is_renewal_authorized, type: Boolean, default: true
    field :renewal_base_year, type: Integer
    field :years_to_renew, type: Integer

    field :is_requesting_voter_registration_application_in_mail, type: Boolean

    field :us_state, type: String
    field :benchmark_product_id, type: BSON::ObjectId

    field :medicaid_terms, type: Boolean
    field :medicaid_insurance_collection_terms, type: Boolean
    field :report_change_terms, type: Boolean
    field :parent_living_out_of_home_terms, type: Boolean
    field :attestation_terms, type: Boolean
    field :submission_terms, type: Boolean

    field :request_full_determination, type: Boolean
    field :integrated_case_id, type: String

    field :is_ridp_verified, type: Boolean
    field :determination_http_status_code, type: Integer
    field :determination_error_message, type: String
    field :has_eligibility_response, type: Boolean, default: false
    field :eligibility_request_payload, type: String
    field :eligibility_response_payload, type: String
    field :full_medicaid_determination, type: Boolean
    field :workflow, type: Hash, default: { }

    embeds_many :applicants, inverse_of: :application, class_name: '::MagiMedicaid::Applicant'

    def set_hbx_id
      write_attribute(:hbx_id, MagiMedicaid::HbxIdGenerator.generate_application_id) if hbx_id.blank?
    end

    def set_request_kind
      write_attribute(:request_kind, "placeholder")
    end

    def set_motivation_kind
      write_attribute(:motivation_kind, "insurance_affordability")
    end

    def set_is_ridp_verified
      write_attribute(:is_ridp_verified, true)
    end

    def set_us_state
      write_attribute(:us_state, MagiMedicaidRegistry[:us_state].setting(:abbreviation).item)
    end

    def set_applicant_kind
      #TODO: Implement logic to handle "call center rep or case worker", "authorized representative"
      write_attribute(:applicant_kind, "user and/or family")
    end

    def ready_for_attestation?
      application_valid = is_application_ready_for_attestation?
      # && chec.k for the validity of all applicants too.
      self.active_applicants.each do |applicant|
        return false unless applicant.applicant_validation_complete?
      end
      application_valid && relationships_complete?
    end

    def is_application_ready_for_attestation?
      self.valid?(:before_attestation) ? true : false
    end

    def before_attestation_validity
      validates_presence_of :hbx_id, :applicant_kind, :request_kind, :motivation_kind, :us_state, :is_ridp_verified
    end
  end
end
