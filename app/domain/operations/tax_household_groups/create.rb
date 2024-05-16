# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module TaxHouseholdGroups
    # this operation is to create taxhouseholdgroups
    class Create
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate(params)
        result = yield create_taxhousehold_group(values[:family], values[:th_group_info])

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. family should be an instance of family') unless params[:family].is_a?(Family)
        return Failure('Missing th_group_info') unless params[:th_group_info]

        Success(params)
      end

      def create_taxhousehold_group(family, th_group_info)
        @effective_date = Date.strptime(th_group_info[:effective_date], '%m/%d/%Y')

        th_group = family.tax_household_groups.build({
                                                       source: 'Admin',
                                                       start_on: @effective_date,
                                                       end_on: nil,
                                                       assistance_year: @effective_date.year,
                                                       tax_households: tax_household_attrs(th_group_info[:tax_households].values)
                                                     })

        th_group.save!
        family.save!
        Success()
      rescue StandardError => e
        Failure("Failed with error: #{e}")
      end

      def tax_household_member_attrs(members)
        members.inject([]) do |result, member_info|
          member_info.deep_symbolize_keys!
          is_ia_eligible = member_info[:pdc_type] == 'is_ia_eligible'

          result << {
            applicant_id: member_info[:family_member_id],
            is_ia_eligible: is_ia_eligible,
            is_medicaid_chip_eligible: member_info[:pdc_type] == 'is_medicaid_chip_eligible',
            is_uqhp_eligible: member_info[:pdc_type] == 'is_uqhp_eligible',
            is_totally_ineligible: member_info[:pdc_type] == 'is_totally_ineligible',
            csr_percent_as_integer: (is_ia_eligible ? member_info[:csr].to_i : 0),
            is_filer: member_info[:is_filer]
          }
          result
        end
      end

      def tax_household_attrs(tax_households_info)
        tax_households_info.inject([]) do |result, tax_household_info|
          members = parse(tax_household_info[:members])
          monthly_expected_contribution = tax_household_info[:monthly_expected_contribution].to_f


          result << {
            yearly_expected_contribution: monthly_expected_contribution * 12,
            effective_starting_on: @effective_date,
            tax_household_members: tax_household_member_attrs(members)
          }
          result
        end
      end

      def parse(stringed_payload)
        JSON.parse(stringed_payload)
      end
    end
  end
end
