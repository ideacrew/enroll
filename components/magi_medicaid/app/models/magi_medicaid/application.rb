# frozen_string_literal: true

module MagiMedicaid
  class Application

    include Mongoid::Document
    include Mongoid::Timestamps

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
  end
end
