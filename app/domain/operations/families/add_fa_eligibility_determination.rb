# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # This operation is to add Financial Assistance Eligibility Determination.
    # Input for this operation is CV3Application where the Financial Assistance Application is in determined state.
    class AddFaEligibilityDetermination
      include Dry::Monads[:result, :do]

      def call(params)
        application_entity = yield validate(params)
        family             = yield find_family(application_entity)
        _deactivated       = yield deactivate_premium_credits(family, application_entity)
        family             = yield create_premium_credits(family, application_entity)

        Success(family)
      end

      private

      def validate(params)
        ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
      end

      def find_family(application_entity)
        primary_hbx_id = application_entity.primary_applicant.person_hbx_id
        people = Person.by_hbx_id(primary_hbx_id)

        if people.count == 1
          Success(people.first.primary_family)
        else
          Failure('Found one or more families for given application')
        end
      end

      def deactivate_premium_credits(family, application_entity)
        new_effective_date = application_entity.tax_households.first.effective_on
        ::Operations::PremiumCredits::Deactivate.new.call({ family: family, new_effective_date: new_effective_date })
      end

      def create_premium_credits(family, application_entity)
        # There are no APTC CSR Eligible Members to create PremiumCredits
        return Success(family) if application_entity.tax_households.map(&:aptc_csr_eligible_members).blank?

        group_premium_credits(family, application_entity).each do |gpc_params|
          result = ::Operations::PremiumCredits::Build.new.call({ gpc_params: gpc_params })

          if result.success?
            group_premium_credit = result.success

            return Failure("Errors persisting group_premium_credit #{group_premium_credit.errors.full_messages}") unless group_premium_credit.save
          end

          Success(family)
        end
      end

      def group_premium_credits(family, application_entity)
        fa_application = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id).first
        return [] if fa_application.nil?

        application_entity.tax_households.inject([]) do |gpcs, thh_entity|
          eligibility_determination = fa_application.eligibility_determinations.where(hbx_assigned_id: thh_entity.hbx_id).first
          mpcs = member_premium_credits(thh_entity, family)
          if mpcs.present?
            gpcs << {
              family_id: family.id,
              kind: 'aptc_csr',
              authority_determination_id: fa_application.id.to_s,
              authority_determination_class: fa_application.class.to_s,
              premium_credit_monthly_cap: thh_entity.max_aptc.to_f,
              sub_group_id: eligibility_determination.id.to_s,
              sub_group_class: eligibility_determination.class.to_s,
              start_on: thh_entity.effective_on,
              member_premium_credits: mpcs
            }
          end

          gpcs
        end
      end

      def member_premium_credits(thh_entity, family)
        thh_entity.aptc_csr_eligible_members.inject([]) do |members, thhm_entity|
          family_member_id = family.family_members.detect { |fm| fm.person.hbx_id == thhm_entity.person_hbx_id }&.id&.to_s

          members << {
            kind: 'aptc_eligible',
            value: 'true',
            start_on: thh_entity.effective_on,
            family_member_id: family_member_id
          }

          members << {
            kind: 'csr',
            value: thhm_entity.csr,
            start_on: thh_entity.effective_on,
            family_member_id: family_member_id
          }
        end
      end
    end
  end
end
