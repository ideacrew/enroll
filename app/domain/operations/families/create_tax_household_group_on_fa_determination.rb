# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # creates taxhousehold groups and it's associations on every financial assistance application determination
    class CreateTaxHouseholdGroupOnFaDetermination
      include Dry::Monads[:do, :result]

      def call(params)
        application_entity = yield validate(params)
        family             = yield find_family(application_entity)
        end_current_taxhousehold_groups(family, application_entity)
        th_group           = yield create_tax_household_groups(application_entity)

        Success(th_group)
      end

      private

      def validate(params)
        ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
      end

      def find_family(application_entity)
        family_hbx_id = application_entity.family_reference.hbx_id
        families = Family.where(hbx_assigned_id: family_hbx_id)

        if families.count == 1
          Success(families.first)
        else
          Failure('Found one or more families for given application')
        end
      end

      def end_current_taxhousehold_groups(family, application_entity)
        new_effective_date = application_entity.tax_households.first.effective_on
        ::Operations::TaxHouseholdGroups::Deactivate.new.call({ deactivate_action_type: 'current_only',
                                                                family: family,
                                                                new_effective_date: new_effective_date })
      end

      def create_tax_household_groups(application_entity)
        family = find_family(application_entity).success
        return Success(family) if application_entity.tax_households.map(&:aptc_csr_eligible_members).blank?

        th_group_params = tax_household_group_params(application_entity)
        th_group = family.tax_household_groups.create(th_group_params)
        family.save!

        Success(th_group)
      end

      def tax_household_member_params(application, determination)
        applicants = application.applicants.where(eligibility_determination_id: determination.id)

        applicants.collect do |applicant|
          {
            applicant_id: applicant.family_member_id,
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
            csr_percent_as_integer: applicant.is_ia_eligible ? applicant.csr_percent_as_integer : 0
          }
        end
      end

      def tax_household_params(application_entity)
        fa_application = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id).first
        return [] unless fa_application

        application_entity.tax_households.collect do |thh_entity|
          ed = fa_application.eligibility_determinations.where(hbx_assigned_id: thh_entity.hbx_id).first
          {
            eligibility_determination_hbx_id: ed.hbx_assigned_id,
            yearly_expected_contribution: ed.yearly_expected_contribution,
            effective_starting_on: ed.effective_starting_on || fa_application.effective_date,
            max_aptc: ed.max_aptc,
            tax_household_members: tax_household_member_params(fa_application, ed)
          }
        end
      end

      def tax_household_group_params(application_entity)
        {
          source: 'Faa',
          application_id: application_entity.hbx_id,
          start_on: application_entity.tax_households.first.effective_on,
          end_on: nil,
          assistance_year: application_entity.assistance_year,
          tax_households: tax_household_params(application_entity)
        }
      end
    end
  end
end
