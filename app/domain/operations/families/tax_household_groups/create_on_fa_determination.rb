# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module TaxHouseholdGroups
      # This operation is for creating TaxHouseholdGroup on FinancialAssistanceApplication determination.
      class CreateOnFaDetermination
        include Dry::Monads[:do, :result]

        def call(application)
          _deactivated = yield deactivate_current_thhg(application)
          thh_group = 	 yield create_new_thhg(application)

          Success(thh_group)
        end

        private

        def deactivate_current_thhg(application)
          new_effective_date = application.eligibility_determinations.pluck(:effective_starting_on).compact.first
          ::Operations::TaxHouseholdGroups::Deactivate.new.call({
                                                                  deactivate_action_type: 'current_only',
                                                                  family: application.family,
                                                                  new_effective_date: new_effective_date
                                                                })
        end

        def create_new_thhg(application)
          family = application.family

          thhg_params = fetch_tax_hh_group_params(application)
          thhg = family.tax_household_groups.build(thhg_params)

          application.eligibility_determinations.each do |elig_deter|
            thh_params = fetch_tax_hh_params(elig_deter, application)
            thh = thhg.tax_households.build(thh_params)

            elig_deter.applicants.each do |applicant|
              thhm_params = fetch_thhm_params(applicant)
              thh.tax_household_members.build(thhm_params)
            end
          end

          if thhg.save
            Success(thhg)
          else
            Failure(thhg.errors.full_messages)
          end
        end

        def fetch_tax_hh_group_params(application)
          { source: 'Faa',
            application_id: application.hbx_id,
            start_on: application.eligibility_determinations.first.effective_starting_on,
            end_on: nil,
            assistance_year: application.assistance_year }
        end

        def fetch_tax_hh_params(elig_deter, application)
          { eligibility_determination_hbx_id: elig_deter.hbx_assigned_id,
            yearly_expected_contribution: elig_deter.yearly_expected_contribution,
            effective_starting_on: elig_deter.effective_starting_on || application.effective_date,
            max_aptc: elig_deter.max_aptc }
        end

        def fetch_thhm_params(applicant)
          { applicant_id: applicant.family_member_id,
            medicaid_household_size: applicant.medicaid_household_size,
            magi_medicaid_category: applicant.magi_medicaid_category,
            magi_as_percentage_of_fpl: applicant.magi_as_percentage_of_fpl,
            magi_medicaid_monthly_income_limit: applicant.magi_medicaid_monthly_income_limit,
            magi_medicaid_monthly_household_income: applicant.magi_medicaid_monthly_household_income,
            is_without_assistance: applicant.is_without_assistance,
            is_ia_eligible: applicant.is_ia_eligible,
            is_medicaid_chip_eligible: applicant.is_medicaid_chip_eligible,
            is_non_magi_medicaid_eligible: applicant.is_non_magi_medicaid_eligible,
            is_totally_ineligible: applicant.is_totally_ineligible,
            csr_percent_as_integer: applicant.is_ia_eligible ? applicant.csr_percent_as_integer : 0,
            member_determinations: member_determinations(applicant)}
        end

        def member_determinations(applicant)
          applicant.member_determinations&.map do |member_determination|
            md_attributes = member_determination.attributes
            md_attributes.except!('_id', 'created_at', 'updated_at')
            eo_attributes = member_determination.eligibility_overrides&.map do |eo|
              eo.attributes.except!('_id', 'created_at', 'updated_at')
            end
            md_attributes['eligibility_overrides'] = eo_attributes
            md_attributes
          end
        end
      end
    end
  end
end
