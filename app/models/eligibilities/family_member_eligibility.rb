# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Evidences
  # distributed across models
  class FamilyMembersEligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :family_eligibility
    embeds_many :family_member_eligibilities
    # Family member eligibility
    class FamilyMemberEligibility
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :family_member

      # Families with family members who are enrolled and have FAA evidences in outstanding status

      # aptc_csr eligibility
      # for tax_household
      #   is income verified?
      # for each family member
      #   are they enrolled? (evidence)
      #   are they on renewal enrollent?
      #   current FAA application
      #     applicant with outstanindg verification? (evidence)
      #  aca_ivl_market eligibility
      #     consumer role
      #     vlp outstanding verification?
      #     immigration outstanding verification

      MARKET_ELIGIBILITIES = [
        :aca_ivl_market_enrollment,
        :aca_shop_market_enrollment,
        :dc_coverall_enrollment
        # :modified_adjusted_gross_income_medicaid, # comprehensive health insurance available to low-income children and adults
        # :childrens_health_insurance_program # provides low-cost health coverage to children in families that earn too much money to qualify for Medicaid but not enough to buy private insurance.
      ].freeze

      #       # ACA IVL Eligibility
      #       { family_member: { aca_ivl_enrollment_evidences: [:vlp, :immigration]} }

      #       { family_member: { aca_ivl_enrollment_evidences: [:active_enrollment, :renewal_enrollment]} }

      # FAA::Application
      # HbxEnrollment
      # ConsumerRole

      # # ACA IVL FAA Eligibility
      # { tax_household: { aptc_csr_credit_evidences: [:income]} }
      # { family_member: { klass: FAA:Application::Applicant, visitor_operatino: Operations::Eligibilites::Evidences::VisitEsi, aptc_csr_credit_evidences: [:esi, :non_esi,  :local_mec]} }

      field :key, type: Symbol
      field :title, type: String
      field :description, type: String

      field :is_satisfied, type: Boolean, default: false
      field :has_outstanding_verifications, type: Boolean, default: false

      # Eligibilty => aca_ivl_market_enrollment_eligible
      #   RDIP, VLP, SSA
      #
      # advance_premium_tax_credit

      embeds_many :eligibilities, class_name: 'Eligibilities::Eligibility'

      before_save :update_eligibility_status

      field :aca_ivl_enrollment_evidences, type: Hash, default: {}
      field :aptc_csr_credit_evidences, type: Hash, default: {}
      field :aca_ivl_market_active_enrollments, type: Hash, default: {}
      field :aca_shop_market_enrollments, type: Hash, default: {}

      has_one :financial_assistance_applicant

      embeds_many :active_enrollments
    end

    ACA_IVL_MARKET_CREDITS = [
      :advance_premium_tax_credit, # tax credits consumers can use to lower their monthly insurance premiums
      :cost_sharing_reduction_credit # discount that lowers the amount a consumer pays for deductibles, copayments, and coinsurance
    ].freeze

    ACA_IVL_MARKET_PRODUCTS = %i[healh_insurance dental_insurance].freeze

    PROGRAMS = [].freeze

    ELIGIBILITY_EVIDENCE_MAP = {
      aca_ivl_market_enrollment_eligible: {
        family: {},
        family_member: {
          verified_lawflly_present: {},
          resident: {}
        }
      },
      family: {},
      advance_premium_tax_credit: {
        application: {},
        applicant: {}
      }
    }.freeze

    ELIGIBLLITY_MAP = {
      group: {
        markets: [:aca_shop_market_enrollment_eligible],
        other: %i[open_enrollment_period plan_design_period]
      },
      family: {
        markets: %i[
          aca_shop_market_enrollment_eligible
          dc_coverall_enrollment_eligible
        ],
        credits: %i[advance_premium_tax_credit cost_sharing_reduction_credit],
        products: []
      }
    }.freeze


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

      eligibilities.reduce([]) do |_list, eligibility|
        eligibility.evidences if ELIGIBILITIES_LIST.include?(eligibility.to_sym)
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
            curam_evidence
          ]
        }
      }
    end

    def product_eligibilities
      {
        aca_ivl_health_product_eligibility: {},
        aca_ivl_catastropic_health_product_eligibility: {},
        aca_ivl_dental_product_eligibility: {},
        aca_shop_health_product_eligibility: {},
        aca_shop_dental_product_eligibility: {},
        evidences: %i[membber_age_evidence family_relationship_evidence]
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
        ],
        evidence_sources: %i[
          fdsh_non_esi_service
          fdsh_esi_service
          fdsh_vlp_service
          fdsh_ifsv_service
          rrv_non_esi_service
          rrv_esi_service
          rrv_vlp_service
          rrv_ifsv_service
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
