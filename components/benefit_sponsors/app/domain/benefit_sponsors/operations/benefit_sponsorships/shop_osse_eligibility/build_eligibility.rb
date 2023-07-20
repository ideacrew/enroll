# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class BuildEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence = yield build_evidence(values)
            eligibility_params = yield build_eligibility_params(values)
            entity = yield create(eligibility_params)
            eligibility = yield build(entity, evidence)
            eligibility_record = yield create_grants(eligibility)

            Success(eligibility_record)
          end
  
          private
  
          def validate(params)
            errors = []
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
  
            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_evidence(params)
            BuildAdminAttestedEvidence.new.call(params)
          end

          def build_eligibility_params(values)
            Success({
              title: values[:evidence_key].to_s.titleize,
              key: values[:evidence_key].to_sym,
              state_histories: [ {
                is_eligible: false,
                from_state: :draft,
                to_state: :draft,
                event: :initialize,
                transition_at: DateTime.now,
                effective_on: values[:effective_date],
                comment: "eligibility record inititalized"
              } ]
            })
          end

          def create(eligibility_params)
            CreateEligibility.new.call(eligibility_params)
          end

          def build(entity, evidence)
            eligibility = BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Eligibility.new(entity.to_h)
            eligibility.shop_osse_evidence = evidence
            if evidence.is_satisfied
              eligibility.move_to_eligible(effective_date: evidence.effective_on)
            else
              eligibility.move_to_ineligible(effective_date: evidence.effective_on)
            end

            Success(eligibility)
          end

          # handle exceptions
          def create_grants(eligibility)
            add_grant(eligibility, :contribution_subsidy_grant, :contribution_subsidy)
            add_grant(eligibility, :min_employee_participation_relaxed_grant, :min_employee_participation_relaxed)
            add_grant(eligibility, :min_fte_count_relaxed_grant, :min_fte_count_relaxed_grant)
            add_grant(eligibility, :min_contribution_relaxed_grant, :min_contribution_relaxed)
            add_grant(eligibility, :metal_level_products_restricted_grant, :metal_level_products_restricted)

            Success(eligibility)
          end

          def add_grant(eligibility, kind, key)
            evidence = eligibility.shop_osse_evidence
            grant = BuildGrant.new.call(build_grant_params(evidence, kind, key))
            eligibility.send("#{kind}=", grant.success)
          end

          def build_grant_params(evidence, kind, key)
            {
              grant_type: kind,
              grant_key: key,
              grant_value: true,
              is_eligible: evidence.is_satisfied,
              effective_date: evidence.effective_on
            }
          end
        end
      end
    end
  end
end
