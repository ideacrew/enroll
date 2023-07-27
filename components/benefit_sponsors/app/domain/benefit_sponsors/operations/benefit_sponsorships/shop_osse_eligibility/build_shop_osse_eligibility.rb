# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# initialize eligibility record 
# eligibility params
# evidence params


# input params 

# event: :initialize 
# event:

# create eligibility
# update evidence

# build eligibility 
# build evidence 
# build grant

# Success({
#   title: values[:evidence_key].to_s.titleize,
#   key: values[:evidence_key].to_sym,
#   state_histories: [ {
#     is_eligible: false,
#     from_state: :draft,
#     to_state: :draft,
#     event: :initialize,
#     transition_at: DateTime.now,
#     effective_on: values[:effective_date],
#     comment: "eligibility record inititalized"
#   } ]
# })



# create_eligibility 




# AcaEntities
#    requires all the params 
#    validates and creates entity
#    validates state transitions 

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class BuildShopOsseEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            evidence_options = yield build_evidence_options(values)
            eligibility_options = yield build_eligibility_options(values, evidence_options)
            # entity = yield create(eligibility_options)
            # eligibility = yield build(entity, evidence)
            # eligibility_record = yield create_grants(eligibility)

            Success(eligibility_options)
          end
  
          private
  
          def validate(params)
            errors = []
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
            state_history = build_state_history_with(values, evidence_options)

            binding.irb
            Success({
                      title: 'Shop Osse Eligibility',
                      key: :shop_osse_eligibility,
                      evidences: [evidence_options],
                      state_histories: [state_history],
                      grants: build_grants(evidence_options)
                  })
          end

          def eligibility_event_for(evidence_options)
            latest_history = evidence_options[:state_histories].first

            case latest_history[:event]
            when :approved
              :publish
            when :denied
              :expire
            else
              :initialize
            end
          end

          def build_grants(evidence_options)
            [
              add_grant(:contribution_subsidy_grant),
              add_grant(:min_employee_participation_relaxed_grant),
              add_grant(:min_fte_count_relaxed_grant),
              add_grant(:min_contribution_relaxed_grant),
              add_grant(:metal_level_products_restricted_grant)
            ]
          end

          def add_grant(key)
            BuildShopOsseGrant.new.call(
              grant_key: key,
              grant_value: true
            ).success
          end

          def build_state_history_with(values, evidence_options)
            eligibility_event = eligibility_event_for(evidence_options)

            {   
              event: values[:event],
              transition_at: DateTime.now,
              effective_on: values[:effective_date],
            }.merge(send("process_#{eligibility_event}"))
          end

          def process_initialize
            {
              is_eligible: false,
              from_state: :initial,
              to_state: :initial,
              event: :initialize,
              comment: "eligibility initialized"
            }
          end

          def process_publish
            {
              is_eligible: true,
              from_state: :initial,
              to_state: :published,
              event: :publish,
              comment: "eligibility published"
            }
          end

          def process_expire
            {
              is_eligible: false,
              from_state: :published,
              to_state: :expired,
              event: :expire,
              comment: "eligibility expired"
            }
          end
        end
      end
    end
  end
end
