# frozen_string_literal: true

module Eligibilities
  module Snapshots
    # Use Visitor Development Pattern to access Eligibilities and Evidences
    # distributed across models
    class FamilySnapshot
      include Mongoid::Document
      include Mongoid::Timestamps

      ELIGIBILITIES_LIST = %i[
        aptc_financial_assistance_eligibility
        magi_medicaid_eligiblility
        chip_eligibility
        enrollment_eligibility
      ].freeze

      field :key, type: Symbol
      field :title, type: String
      field :description, type: String
      field :is_satisfied, type: Boolean, default: false
      field :has_unsatisfied_eligibilities, type: Boolean, default: true

      embeds_many :eligibilities, class_name: 'Eligibilities::Eligibility'

      before_save :update_eligibility_status

      # field :enrollment_period
      # @return [Array<Eligibility>]
      def unsatisfied_eligibilities
        eligibilities.reduce([]) do |list, eligibility|
          list << eligibility unless eligibility.is_satisfied
          list
        end
      end

      # @param [Family] the subject family instance
      # @param [Date] the date upon which to base the snapshot's
      #    eligibility determinations
      # @param options [Hash] options for generating the snapshot
      # @option options {Array<ELIGIBILITES_LIST>} :eligibilities
      #    list of eligibility keys to geerate for this snapshot.
      #    Default is :all
      # @return [Array<Eligibility>]
      def snap(_family, _effective_date = Date.today, options = {})
        eligibilities = options[:eligibilities].slice || [:all]

        eligibilities = ELIGIBILITIES_LIST if eligibilities.include?(:all)

        eligibilities.reduce([]) do |list, eligibility|
          next list unless ELIGIBILITIES_LIST.include?(eligibility.to_sym)
          eligibility.evidences
        end
      end

      def family_eligibilities
        {
          enrollment_eligibility: {
            evidences: %i[
              open_enrollment_evidence
              special_enrollment_period_evidence
              native_american_enrollment_period_evidence
            ]
          }
        }
      end

      def tax_household_eligibilities
        {
          aptc_financial_assistance_eligibility: {
            evidences: %i[
              income_evidence
              ideacrew_mitc_evidence
              haven_evidence
              ffm_evidence
              ios_evidence
            ]
          }
        }
      end

      def product_eligibilities
        {
          aca_ivl_health_product_eligibility: {},
          aca_ivl_dental_product_eligibility: {},
          aca_shop_health_product_eligibility: {},
          aca_shop_dental_product_eligibility: {},
          evidences: %i[
            open_enrollment_period_evidence
            special_enrollment_period_evidence
            dependent_age_evidence
            family_relationship_evidence
          ]
        }
      end

      def member_eligibilities
        {
          magi_medicaid_eligibility: {},
          chip_eligibility: {},
          member_financial_assistance_eligibility: {},
          evidences: %i[
            residency_evidence
            age_evidence
            non_incarcerated_evidence
            lawful_presence_evidence
            immigration_evidence
            native_american_heritage_evidence
            tax_household_member_evidence
            fdsh_non_esi_evidence
            fdsh_esi_evidence
            fdsh_vlp_evidence
            fdsh_ifsv_evidence
            rrv_non_esi_evidence
            rrv_esi_evidence
            rrv_vlp_evidence
            rrv_ifsv_evidence
          ]
        }
      end

      def eligibilities; end

      private

      def update_eligibility_status
        if unsatisfied_eligibilities.empty?
          write_attribute(:has_unsatisfied_eligibilities, false)
        else
          write_attribute(:has_unsatisfied_eligibilities, true)
        end
      end
    end
  end
end
