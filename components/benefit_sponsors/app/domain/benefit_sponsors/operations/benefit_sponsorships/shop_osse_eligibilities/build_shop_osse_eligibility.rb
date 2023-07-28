# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support eligibility creation
        class BuildShopOsseEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<GlobalId>]   :subject required
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence_options = yield build_evidence_options(values)
            eligibility_options = yield build_eligibility_options(values, evidence_options)

            Success(eligibility_options)
          end
  
          private
  
          def validate(params)
            errors = []
            errors << 'subject missing' unless params[:subject]
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
            errors << 'event missing' unless params[:event]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_evidence_options(values)
            BuildAdminAttestedEvidence.new.call(values)
          end

          def build_eligibility_options(values, evidence_options)
            eligibility = {
              title: 'Shop Osse Eligibility',
              key: :shop_osse_eligibility,
              evidences: [evidence_options],
              grants: build_grants,
              state_histories: [build_state_history(values, evidence_options)]
            }
       
            Success(eligibility)
          end          

          def build_grants
            grants = [
              :contribution_subsidy_grant,
              :min_employee_participation_relaxed_grant,
              :min_fte_count_relaxed_grant,
              :min_contribution_relaxed_grant,
              :metal_level_products_restricted_grant
            ].map do |key|
              BuildShopOsseGrant.new.call(
                grant_key: key,
                grant_value: true
              ).success
            end

            grants
          end

          def build_state_history(values, evidence_options)
            eligibility_event = eligibility_event_for(evidence_options)
          
            state_history = {
              event: values[:event],
              transition_at: DateTime.now,
              effective_on: values[:effective_date],
              is_eligible: evidence_options[:is_satisfied]
            }

            state_history.merge!(states_for(eligibility_event))
          end
          
          def eligibility_event_for(evidence_options)
            latest_history = evidence_options[:state_histories].first
          
            case latest_history[:event]
            when :approved then :publish
            when :denied then :expire
            else :initialize
            end
          end

          def states_for(event)
            case event              
            when :publish
              { from_state: :initial, to_state: :published }
            when :expire
              { from_state: :initial, to_state: :expired }
            else
              { from_state: :initial, to_state: :initial }
            end
          end
        end
      end
    end
  end
end
