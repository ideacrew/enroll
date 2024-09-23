# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibilityDetermination
      include Dry::Monads[:do, :result]

      def call(application)
        values = yield validate(application) #application_contract
        family = yield find_family(values[:family_id])
        result = yield add_determination(family, values)

        Success(result)
      end

      private

      def validate(application)
        @application = application
        params = @application.attributes
        contract_result = Validators::Families::EligibilityDeterminationContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: family_id)
      end

      def add_determination(family, values)
        deactivate_latest_tax_households(values)
        benchmark_plan_id = values[:benchmark_product_id]
        values[:eligibility_determinations].each do |faa_ed|
          applicants = values[:applicants].select{|app| app["eligibility_determination_id"] == faa_ed["_id"]}
          assistance_criteria = applicants.pluck("is_ia_eligible", "is_medicaid_chip_eligible", "is_totally_ineligible", "is_magi_medicaid", "is_non_magi_medicaid_eligible", "is_without_assistance")
          next unless assistance_criteria.flatten.any?(true)

          parsed_yearly_expected_contribution = if faa_ed["yearly_expected_contribution"].present?
                                                  yearly_expected_contribution = Money.new(faa_ed["yearly_expected_contribution"]["cents"], 'USD')
                                                  yearly_expected_contribution.to_f > 0.00 ? yearly_expected_contribution.to_f : 0.00
                                                end

          th = family.active_household.tax_households.build(hbx_assigned_id: faa_ed["hbx_assigned_id"],
                                                            effective_starting_on: faa_ed["effective_starting_on"],
                                                            yearly_expected_contribution: parsed_yearly_expected_contribution,
                                                            is_eligibility_determined: faa_ed["is_eligibility_determined"])
          applicants.each do |applicant| #todo select instead
            create_tax_household_members(family, th, applicant, faa_ed)
          end

          build_eligibility_determinations(th, faa_ed, benchmark_plan_id)
        end
        family.active_household.save!
        update_family_attributes(family, values[:integrated_case_id])

        Success(family)
      end

      def build_eligibility_determinations(tax_household, faa_ed, benchmark_plan_id)
        max_aptc = Money.new(faa_ed["max_aptc"]["cents"], 'USD')
        verified_aptc = max_aptc.to_f > 0.00 ? max_aptc.to_f : 0.00
        tax_household.eligibility_determinations.build(
          benchmark_plan_id: benchmark_plan_id,
          max_aptc: verified_aptc,
          determined_at: faa_ed["determined_at"],
          aptc_csr_annual_household_income: faa_ed["aptc_csr_annual_household_income"],
          aptc_annual_income_limit: faa_ed["aptc_annual_income_limit"],
          csr_annual_income_limit: faa_ed["csr_annual_income_limit"],
          source: faa_ed["source"]
        ).save
      end

      def create_tax_household_members(family, tax_household, applicant, _faa_ed)
        family_member = fetch_family_member_from_applicant(family, applicant)

        return Failure('Unable to find family member') if family_member.blank?
        is_ia_eligible = applicant["is_ia_eligible"] == "true" || applicant["is_ia_eligible"] == true

        tax_household.tax_household_members.build(
          applicant_id: family_member.id,
          medicaid_household_size: applicant["medicaid_household_size"],
          magi_medicaid_category: applicant["magi_medicaid_category"],
          magi_as_percentage_of_fpl: applicant["magi_as_percentage_of_fpl"],
          magi_medicaid_monthly_income_limit: applicant["magi_medicaid_monthly_income_limit"],
          magi_medicaid_monthly_household_income: applicant["magi_medicaid_monthly_household_income"],
          is_without_assistance: applicant["is_without_assistance"],
          is_ia_eligible: applicant["is_ia_eligible"],
          is_medicaid_chip_eligible: applicant["is_medicaid_chip_eligible"],
          is_non_magi_medicaid_eligible: applicant["is_non_magi_medicaid_eligible"],
          is_totally_ineligible: applicant["is_totally_ineligible"],
          csr_percent_as_integer: is_ia_eligible ? applicant["csr_percent_as_integer"] : 0,
          member_determinations: member_determinations(applicant)
        )
      end

      def member_determinations(applicant)
        member_determinations = @application.applicants.detect {|a| a.person_hbx_id == applicant["person_hbx_id"]}.member_determinations
        member_determinations.map do |md|
          md_attributes = md.attributes
          md_attributes.except!('_id', 'created_at', 'updated_at')
          eo_attributes = md.eligibility_overrides&.map do |eo|
            eo.attributes.except!('_id', 'created_at', 'updated_at')
          end
          md_attributes['eligibility_overrides'] = eo_attributes
          md_attributes
        end
      end

      def fetch_family_member_from_applicant(family, applicant)
        person = Person.where(hbx_id: applicant["person_hbx_id"]).first
        family.family_members.where(person_id: person.id).first
      end

      def deactivate_latest_tax_households(values)
        primary_applicant = values[:applicants].select{|app| app["is_primary_applicant"]}.first
        ed = values[:eligibility_determinations].select{|ed| ed["_id"] == primary_applicant["eligibility_determination_id"]}.first
        Operations::Households::DeactivateFinancialAssistanceEligibility.new.call(params: { deactivate_action_type: 'current_only', family_id: values[:family_id], date: ed["effective_starting_on"]})
      end

      def update_family_attributes(family, case_id)
        family.e_case_id = case_id
        Success(family.save!)
      end
    end
  end
end
