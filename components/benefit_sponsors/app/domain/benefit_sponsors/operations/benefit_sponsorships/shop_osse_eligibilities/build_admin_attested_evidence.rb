# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support eligibility creation
        class BuildAdminAttestedEvidence
          send(:include, Dry::Monads[:result, :do])

          ELIGIBLE_STATUSES = %i[accepted].freeze
          EVENTS = %i[move_to_initial move_to_approved move_to_denied].freeze

          STATE_MAPPING = {
            initial: [:initial],
            accepted: [:initial, :denied],
            denied: [:initial, :accepted]
          }.freeze

          # @param [Hash] opts Options to build eligibility
          # @option opts [<GlobalId>] :subject required
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [<Symbol>]   :event required
          # @option opts [Date]       :effective_date required
          # @option opts [Date]       :evidence_record required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence_options = yield build(values)

            Success(evidence_options)
          end

          private

          def validate(params)
            errors = []
            errors << 'subject missing' unless params[:subject]
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
            errors << 'event missing' unless params[:event]
            errors << 'evidence_record missing' unless params[:evidence_record]

            errors << "Event: #{params[:event]} Invalid. It should be one of #{EVENTS}" unless EVENTS.include?(params[:event])

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build(values)
            options = build_default_evidence_options(values)
            state_history_options = build_state_history(values)

            options[:state_histories] ||= []
            options[:state_histories] << state_history_options
            options[:is_satisfied] = state_history_options[:is_eligible]

            Success(options)
          end

          def build_default_evidence_options(values)
            if values[:evidence_record]&.persisted?
              values[:evidence_record].serializable_hash.deep_symbolize_keys
            else
              {
                title: values[:evidence_key].to_s.titleize,
                key: values[:evidence_key].to_sym,
                subject_ref: values[:subject].uri,
                evidence_ref: URI("gid://enroll_app/BenefitSponsorships/ShopOsseEvidence")
              }
            end
          end

          def build_state_history(values)
            from_state = values[:evidence_record].state_histories.last&.to_state
            options = {
              event: values[:event],
              transition_at: DateTime.now,
              effective_on: values[:effective_date],
              from_state: from_state || :initial,
              to_state: to_state(values[:event])
            }

            options[:is_eligible] = ELIGIBLE_STATUSES.include?(options[:to_state]) if options[:to_state]
            options
          end

          def to_state(event)
            event.to_s.match(/move_to_(.*)/)[1].to_sym
          end
        end
      end
    end
  end
end
