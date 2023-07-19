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
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence_params = yield build_evidence_params(values)
            entity = yield create(evidence_params)
            evidence = yield build(entity, values)

            Success(evidence)
          end

          private

          def validate(params)
            errors = []
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_evidence_params(values)
            Success({
                      title: values[:evidence_key].to_s.titleize,
                      key: values[:evidence_key].to_sym,
                      is_satisfied: false,
                      state_histories: [
                                          {
                                            is_eligible: false,
                                            from_state: :initialized,
                                            to_state: :initialized,
                                            event: :initialize,
                                            transition_at: DateTime.now,
                                            effective_on: values[:effective_date],
                                            comment: "evidence inititalized"
                                          }
                                        ]
                    })
          end

          def create(evidence_params)
            CreateAdminAttestedEvidence.new.call(evidence_params)
          end

          def build(entity, values)
            evidence = BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::AdminAttestedEvidence.new(entity.to_h)
            if values[:evidence_value] == 'true'
              evidence.attest(values.slice(:effective_date))
            else
              evidence.negative_response_received(values.slice(:effective_date))
            end

            Success(evidence)
          end
        end
      end
    end
  end
end
