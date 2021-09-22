# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation creates a new renewal_draft application from a given family identifier(BSON ID),
      class CreateRenewalDraft
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to generate renewal_draft application
        # @option opts [BSON::ObjectId] :family_id (required)
        # @option opts [Integer] :renewal_year (required)
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params       = yield validate_input_params(params)
          latest_application     = yield find_latest_application(validated_params)
          determined_application = yield check_application_state(latest_application)
          renewal_draft_app      = yield create_renewal_draft_application(determined_application, validated_params)

          Success(renewal_draft_app)
        end

        private

        def validate_input_params(params)
          return Failure('Missing family_id key') unless params.key?(:family_id)
          return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
          return Failure("Invalid value: #{params[:family_id]} for key family_id, must be a valid object identifier") if params[:family_id].nil?
          return Failure("Cannot find family with input value: #{params[:family_id]} for key family_id") if ::Family.where(id: params[:family_id]).first.nil?
          return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
          Success(params)
        end

        def find_latest_application(validated_params)
          application = ::FinancialAssistance::Application.where(family_id: validated_params[:family_id], assistance_year: validated_params[:renewal_year].pred).created_asc.last
          application.present? ? Success(application) : Failure("Could not find any applications with the given inputs params: #{validated_params}.")
        end

        # Currently, we only allow applications which are in submitted or determined.
        def check_application_state(latest_application)
          eligible_states = ::FinancialAssistance::Application::RENEWAL_ELIGIBLE_STATES
          return Failure("Cannot generate renewal_draft for given application with aasm_state #{latest_application.aasm_state}. Application must be in one of #{eligible_states} states.") if eligible_states.exclude?(latest_application.aasm_state)
          Success(latest_application)
        end

        def create_renewal_draft_application(application, validated_params)
          service = ::FinancialAssistance::Services::ApplicationService.new(application_id: application.id)
          draft_app = service.copy!
          draft_app.save!
          attach_additional_data(draft_app, application, validated_params)
          Success(draft_app)
        rescue StandardError => e
          Rails.logger.error "---CreateRenewalDraft: Unable to generate Renewal Draft Application for application with hbx_id: #{application.hbx_id}, error: #{e.backtrace}"
          Failure("Could not generate renewal draft for given application with hbx_id: #{application.hbx_id}, error: #{e.message}")
        end

        def attach_additional_data(draft_app, application, validated_params)
          years_to_renew = calculate_years_to_renew(application)
          # Using update attributes instead of calling aasm event becuase 'renewal_draft' is the first state for a renewal application.
          draft_app.update_attributes!(
            { aasm_state: 'renewal_draft',
              assistance_year: validated_params[:renewal_year],
              years_to_renew: years_to_renew,
              renewal_base_year: application.renewal_base_year,
              predecessor_id: application.id }
          )
        end

        # Deduct one year from years_to_renew as this is a renewal application(application for prospective year)
        def calculate_years_to_renew(application)
          return 0 if application.years_to_renew.nil? || !application.years_to_renew.positive?
          application.years_to_renew.pred
        end
      end
    end
  end
end
