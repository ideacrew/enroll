# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'


# create an operation that will take
  # Yes/No for eligibility
  # date

  # BuildEligibility
     # validate params
     # construct evidence params
     # construct evidence object
     # update eligibility
        # if evidence is eligible, move to eligible
        # if evidence ineligible, move to ineligible
     # create grants with active/expired state
     #   based on evidence being eligible
     #   based on evidence not eligible

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class BuildAdminAttestedEvidence
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [<Symbol>]   :event required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence_options = yield build_evidence_options(values)

            Success(evidence_options)
          end

          private


          def validate(params)
            errors = []
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
            errors << 'event missing' unless params[:event]

            unless evidence_events.include?(params[:event])
              errors << "even: #{params[:event]} invalid. It should be one of #{evidence_events}"
            end

            errors.empty? ? Success(params) : Failure(errors)
          end

          def evidence_events
            [:initialize, :accept, :deny]
          end

          def build_evidence_options(values)
            state_history = build_state_history_with(values)

            Success({
                      title: values[:evidence_key].to_s.titleize,
                      key: values[:evidence_key].to_sym,
                      is_satisfied: state_history[:is_eligible],
                      state_histories: [state_history],
                      subject_ref: URI("gid://enroll_app/People/Consumer"),
                      evidence_ref: URI("gid://enroll_app/People/Evidence")
                  })
          end

          def build_state_history_with(values)
            {   
              event: values[:event],
              transition_at: DateTime.now,
              effective_on: values[:effective_date],
            }.merge(send("process_#{values[:event]}"))
          end

          def process_initialize
            {
              is_eligible: false,
              from_state: :initial,
              to_state: :initial,
              event: :initialize,
              comment: "evidence initialized"
            }
          end

          def process_accept
            {
              is_eligible: true,
              from_state: :initial,
              to_state: :accepted,
              event: :accept,
              comment: "eligibility accepted"
            }
          end

          def process_deny
            {
              is_eligible: false,
              from_state: :accept,
              to_state: :denied,
              event: :denied,
              comment: "eligibility denied"
            }
          end
        end
      end
    end
  end
end
