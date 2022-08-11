# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Actions
    # This class is for Creating Eligibility for admin tool "Create Eligibility".
    class CreateEligibility
      include Dry::Monads[:result, :do]

      # Find Family, TransformParams, DeactivatePremiumCredits, CreatePremiumCredits
      def call(params)
        family                 = yield find_family(params)
        premium_credit_params  = yield transform_params(params, family)
        _deactivated           = yield deactivate_premium_credits(family, premium_credit_params)
        family                 = yield create_premium_credits(family, premium_credit_params)

        Success(family)
      end

      private

      def find_family(params)
        people = Person.where(id: params[:person_id])

        if people.count == 1
          family = people.first.primary_family
          if family.present?
            Success(family)
          else
            Failure("No Primary Family found for person with person_id: #{params[:person_id]}")
          end
        else
          Failure("Found one or more people for given person_id: #{params[:person_id]}")
        end
      end

      def transform_params(params, family)
        tranformed_params = {
          family_id: family.id,
          kind: 'aptc_csr',
          premium_credit_monthly_cap: params[:max_aptc],
          start_on: params[:effective_date],
          member_premium_credits: member_premium_credits(params, family)
        }

        Success(tranformed_params)
      end

      def member_premium_credits(params, family)
        members = []
        params[:family_members].each do |person_hbx_id, additional_info|
          next unless additional_info[:pdc_type] == 'is_ia_eligible'
          family_member_id = family.family_members.detect { |fm| fm.person.hbx_id == person_hbx_id }.id.to_s
          members << {
            kind: 'aptc_eligible',
            value: 'true',
            start_on: params[:effective_date],
            family_member_id: family_member_id
          }

          members << {
            kind: 'csr',
            value: params[:csr],
            start_on: params[:effective_date],
            family_member_id: family_member_id
          }
        end
        members
      end

      def deactivate_premium_credits(family, gpc_params)
        ::Operations::PremiumCredits::Deactivate.new.call({ family: family,
                                                            new_effective_date: gpc_params[:start_on].to_date })
      end

      def create_premium_credits(family, gpc_params)
        # There are no APTC/CSR eligible members to create PremiumCredits
        return Success(family) if gpc_params[:member_premium_credits].blank?

        result = ::Operations::PremiumCredits::Build.new.call({ gpc_params: gpc_params })

        if result.success?
          group_premium_credit = result.success

          return Failure("Errors persisting group_premium_credit #{group_premium_credit.errors.full_messages}") unless group_premium_credit.save

          Success(family)
        else
          Failure("Unable to build Group Premium Credit, failure: #{failure_message(result)} ")
        end
      end

      def failure_message(result)
        failure = result.failure
        case failure
        when Dry::Validation::Result
          failure.errors.to_h
        else
          failure
        end
      end
    end
  end
end
