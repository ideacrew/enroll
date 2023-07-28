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

          INELIGIBLE_STATUSES = %i[initial denied].freeze
          ELIGIBLE_STATUSES = %i[accepted].freeze
          EVENTS = %i[initialize accept deny].freeze

          # @param [Hash] opts Options to build eligibility
          # @option opts [<GlobalId>] :subject required
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [<Symbol>]   :event required
          # @option opts [Date]       :effective_date required
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

            unless EVENTS.include?(params[:event])
              errors << "Event: #{params[:event]} Invalid. It should be one of #{EVENTS}"
            end

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build(values)
            state_history = build_state_history(values)

            Success({
                      title: values[:evidence_key].to_s.titleize,
                      key: values[:evidence_key].to_sym,
                      is_satisfied: state_history[:is_eligible],
                      state_histories: [state_history],
                      subject_ref: values[:subject].uri,
                      evidence_ref: URI("gid://enroll_app/BenefitSponsorships/ShopOsseEvidence")
                  })
          end

          def build_state_history(values)
            transition_states = states_for(values[:event])

            {   
              event: values[:event],
              transition_at: DateTime.now,
              effective_on: values[:effective_date],
              is_eligible: ELIGIBLE_STATUSES.include?(transition_states[:to_state]),
              event: values[:event]
            }.merge(transition_states)
          end

          def states_for(event)
            case event
            when :accept
              { from_state: :initial, to_state: :accepted }
            when :deny
              { from_state: :initial, to_state: :denied }
            else
              { from_state: :initial, to_state: :initial }
            end
          end      
        end
      end
    end
  end
end
