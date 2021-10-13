# frozen_string_literal: true
module FinancialAssistance
  class Benefit
    include Mongoid::Document
    include Mongoid::Timestamps

    before_create :set_submission_timestamp

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'
    embeds_one :employer_address, class_name: 'FinancialAssistance::Locations::Address', validate: (EnrollRegistry[:skip_employer_address_validation].enabled? ? false : true), cascade_callbacks: true
    embeds_one :employer_phone, class_name: 'FinancialAssistance::Locations::Phone', validate: (EnrollRegistry[:skip_employer_phone_validation].enabled? ? false : true), cascade_callbacks: true

    TITLE_SIZE_RANGE = (3..30).freeze
    STATE_HEALTH_BENEFITS = %w[medicaid].freeze

    INSURANCE_KINDS = %w[
      private_individual_and_family_coverage
      acf_refugee_medical_assistance
      americorps_health_benefits
      child_health_insurance_plan
      medicaid
      medicare
      medicare_advantage
      medicare_part_b
      state_supplementary_payment
      tricare
      veterans_benefits
      naf_health_benefit_program
      health_care_for_peace_corp_volunteers
      department_of_defense_non_appropriated_health_benefits
      cobra
      employer_sponsored_insurance
      self_funded_student_health_coverage
      foreign_government_health_coverage
      private_health_insurance_plan
      coverage_obtained_through_another_exchange
      coverage_under_the_state_health_benefits_risk_pool
      veterans_administration_health_benefits
      peace_corps_health_benefits
      health_reimbursement_arrangement
      retiree_health_benefits
      other_full_benefit_coverage
      other_limited_benefit_coverage
      ].freeze

    KINDS = %w[
      is_eligible
      is_enrolled
    ].freeze

    INSURANCE_TYPE = {
      private_individual_and_family_coverage: "#{Settings.site.short_name} Individual & Family coverage",
      acf_refugee_medical_assistance: 'ACF Refugee Medical Assistance',
      americorps_health_benefits: 'AmeriCorps health benefits',
      child_health_insurance_plan: "Children's Health Insurance Program",
      medicaid: 'Medicaid',
      medicare: 'Medicare',
      medicare_advantage: 'Medicare Advantage',
      medicare_part_b: 'Medicare Part B',
      state_supplementary_payment: 'State Supplementary Payment',
      tricare: 'TRICARE',
      veterans_benefits: 'Veterans benefits',
      naf_health_benefit_program: 'NAF Health Benefits Program',
      health_care_for_peace_corp_volunteers: 'Health care for Peace Corps volunteers',
      department_of_defense_non_appropriated_health_benefits: 'Department of Defense Nonappropriated Fund health benefits',
      cobra: 'COBRA',
      employer_sponsored_insurance: 'Employer-sponsored insurance',
      self_funded_student_health_coverage: 'Self-funded student health coverage',
      foreign_government_health_coverage: 'Foreign government health coverage',
      private_health_insurance_plan: 'Private health insurance plan',
      coverage_obtained_through_another_exchange: "Coverage obtained through a non-#{Settings.site.short_name} marketplace",
      coverage_under_the_state_health_benefits_risk_pool: 'Coverage under the state health benefits risk pool',
      veterans_administration_health_benefits: 'Veterans Administration health benefits',
      peace_corps_health_benefits: 'Peace Corps health benefits',
      health_reimbursement_arrangement: 'Health Reimbursement Arrangement',
      retiree_health_benefits: 'Retiree Health Benefits',
      other_full_benefit_coverage: 'Other full benefit coverage',
      other_limited_benefit_coverage: 'Other limited benefit coverage'
    }.freeze

    ESI_COVERED_KINDS = %w[self self_and_spouse family].freeze

    field :title, type: String
    field :esi_covered, type: String
    field :kind, type: String
    field :insurance_kind, type: String
    field :hra_type, type: String

    field :is_employer_sponsored, type: Boolean
    field :is_esi_waiting_period, type: Boolean
    field :is_esi_mec_met, type: Boolean
    field :employee_cost, type: Money, default: 0.00
    field :employee_cost_frequency, type: String

    field :start_on, type: Date
    field :end_on, type: Date
    field :submitted_at, type: DateTime

    field :workflow, type: Hash, default: { }

    field :employer_name, type: String
    field :employer_id, type: String, default: ''

    scope :eligible, -> { where(kind: 'is_eligible')}
    scope :enrolled, -> { where(kind: 'is_enrolled')}
    scope :of_insurance_kind, ->(insurance_kind) { where(insurance_kind: insurance_kind) }

    scope :any_medicare, -> { where(:insurance_kind.in => ['medicare', 'medicare_advantage', 'medicare_part_b']) }

    validates_length_of :title,
                        in: TITLE_SIZE_RANGE,
                        allow_nil: true,
                        message: "pick a name length between #{TITLE_SIZE_RANGE}",
                        on: [:step_1, :submission]

    validates :kind, presence: true,
                     inclusion: {
                       in: KINDS,
                       message: '%{value} is not a valid benefit kind type'
                     },
                     on: [:step_1, :submission]

    validates :insurance_kind, presence: true,
                               inclusion: {
                                 in: INSURANCE_KINDS,
                                 message: '%{value} is not a valid benefit insurance kind type'
                               },
                               on: [:step_1, :submission]

    validate :presence_of_esi_details_if_esi,
             :presence_of_dates_if_enrolled,
             on: [:step_1, :submission]

    alias is_employer_sponsored? is_employer_sponsored

    def is_eligible?
      kind == 'is_eligible'
    end

    def is_enrolled?
      kind == 'is_enrolled'
    end

    # Eligibility through public employee
    def is_state_health_benefit?; end

    def clean_conditional_params(params)
      clean_params(params)
    end

    class << self
      def duplicate_employer_address(source_employer_address)
        rejected_attrs = ::FinancialAssistance::Applicant::EVIDENCE_EXCLUDED_PARAMS
        source_employer_address.attributes.reduce({}) do |new_attrs, attr|
          new_attrs.merge!({ attr.first => attr.second }) unless rejected_attrs.include?(attr.first)
          new_attrs
        end
      end

      def duplicate_employer_phone(source_employer_phone)
        rejected_attrs = ::FinancialAssistance::Applicant::EVIDENCE_EXCLUDED_PARAMS
        source_employer_phone.attributes.reduce({}) do |new_attrs, attr|
          new_attrs.merge!({ attr.first => attr.second }) unless rejected_attrs.include?(attr.first)
          new_attrs
        end
      end

      def dup_instance(source_instance)
        rejected_attrs = ::FinancialAssistance::Applicant::EVIDENCE_EXCLUDED_PARAMS
        new_instance_params = source_instance.attributes.reduce({}) do |new_attrs, attr|
          new_attrs.merge!({ attr.first => attr.second }) unless rejected_attrs.include?(attr.first)
          new_attrs
        end
        new_instance = new(new_instance_params)
        new_instance.employer_address = ::FinancialAssistance::Locations::Address.new(duplicate_employer_address(source_instance.employer_address)) if source_instance.employer_address.present?
        new_instance.employer_phone = ::FinancialAssistance::Locations::Phone.new(duplicate_employer_phone(source_instance.employer_phone)) if source_instance.employer_phone.present?
        new_instance
      end

      def find(id)
        bson_id = BSON::ObjectId.from_string(id.to_s)
        applications = ::FinancialAssistance::Application.where('applicants.benefits._id' => bson_id)
        return unless applications.size == 1
        applicants = applications.first.applicants.where('benefits._id' => bson_id)
        applicants.size == 1 ? applicants.first.benefits.find(bson_id) : nil
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def valid_insurance_kinds
        i_kinds = []
        i_kinds << "private_individual_and_family_coverage" if FinancialAssistanceRegistry.feature_enabled?(:private_individual_and_family_coverage)
        i_kinds << "acf_refugee_medical_assistance" if FinancialAssistanceRegistry.feature_enabled?(:acf_refugee_medical_assistance)
        i_kinds << "americorps_health_benefits" if FinancialAssistanceRegistry.feature_enabled?(:americorps_health_benefits)
        i_kinds << "child_health_insurance_plan" if FinancialAssistanceRegistry.feature_enabled?(:child_health_insurance_plan)
        i_kinds << "medicaid" if FinancialAssistanceRegistry.feature_enabled?(:medicaid)
        i_kinds << "medicare" if FinancialAssistanceRegistry.feature_enabled?(:medicare)
        i_kinds << "medicare_advantage" if FinancialAssistanceRegistry.feature_enabled?(:medicare_advantage)
        i_kinds << "medicare_part_b" if FinancialAssistanceRegistry.feature_enabled?(:medicare_part_b)
        i_kinds << "state_supplementary_payment" if FinancialAssistanceRegistry.feature_enabled?(:state_supplementary_payment)
        i_kinds << "tricare" if FinancialAssistanceRegistry.feature_enabled?(:tricare)
        i_kinds << "veterans_benefits" if FinancialAssistanceRegistry.feature_enabled?(:veterans_benefits)
        i_kinds << "naf_health_benefit_program" if FinancialAssistanceRegistry.feature_enabled?(:naf_health_benefit_program)
        i_kinds << "health_care_for_peace_corp_volunteers" if FinancialAssistanceRegistry.feature_enabled?(:health_care_for_peace_corp_volunteers)
        i_kinds << "department_of_defense_non_appropriated_health_benefits" if FinancialAssistanceRegistry.feature_enabled?(:department_of_defense_non_appropriated_health_benefits)
        i_kinds << "cobra" if FinancialAssistanceRegistry.feature_enabled?(:cobra_benefit_fa)
        i_kinds << "employer_sponsored_insurance" if FinancialAssistanceRegistry.feature_enabled?(:employer_sponsored_insurance)
        i_kinds << "self_funded_student_health_coverage" if FinancialAssistanceRegistry.feature_enabled?(:self_funded_student_health_coverage)
        i_kinds << "foreign_government_health_coverage" if FinancialAssistanceRegistry.feature_enabled?(:foreign_government_health_coverage)
        i_kinds << "private_health_insurance_plan" if FinancialAssistanceRegistry.feature_enabled?(:private_health_insurance_plan)
        i_kinds << "coverage_obtained_through_another_exchange" if FinancialAssistanceRegistry.feature_enabled?(:coverage_obtained_through_another_exchange)
        i_kinds << "coverage_under_the_state_health_benefits_risk_pool" if FinancialAssistanceRegistry.feature_enabled?(:coverage_under_the_state_health_benefits_risk_pool)
        i_kinds << "veterans_administration_health_benefits" if FinancialAssistanceRegistry.feature_enabled?(:veterans_administration_health_benefits)
        i_kinds << "peace_corps_health_benefits" if FinancialAssistanceRegistry.feature_enabled?(:peace_corps_health_benefits)
        i_kinds << "health_reimbursement_arrangement" if FinancialAssistanceRegistry.feature_enabled?(:health_reimbursement_arrangement)
        i_kinds << "retiree_health_benefits" if FinancialAssistanceRegistry.feature_enabled?(:retiree_health_benefits)
        i_kinds << "other_full_benefit_coverage" if FinancialAssistanceRegistry.feature_enabled?(:other_full_benefit_coverage)
        i_kinds << "other_limited_benefit_coverage" if FinancialAssistanceRegistry.feature_enabled?(:other_limited_benefit_coverage)

        i_kinds
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize
    end

    private

    def clean_params(params)
      model_params = params[:benefit]

      return unless model_params.present? && model_params[:insurance_kind] != 'employer_sponsored_insurance'
      clean_benefit_params_when_not_esi(model_params)
      clean_employer_params_when_not_esi(params)
    end

    def clean_benefit_params_when_not_esi(model_params)
      model_params[:esi_covered] = nil
      model_params[:employer_name] = nil
      model_params[:employer_id] = nil
      model_params[:employee_cost] = nil
      model_params[:employee_cost_frequency] = nil
      model_params[:is_esi_mec_met] = nil
      model_params[:is_esi_waiting_period] = nil
    end

    def clean_employer_params_when_not_esi(params)
      params[:employer_address][:address_1] = nil
      params[:employer_address][:address_2] = nil
      params[:employer_address][:city] = nil
      params[:employer_address][:state] = nil
      params[:employer_address][:zip] = nil
      params[:employer_phone][:full_phone_number] = nil
    end

    def set_submission_timestamp
      write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
    end

    def start_on_must_precede_end_on(start_on, end_on)
      return unless start_on.present? && end_on.present?
      errors.add(:end_on, "End On Date can't occur before Start On Date") if end_on < start_on
    end

    def presence_of_dates_if_enrolled
      return unless is_enrolled?
      errors.add(:start_on, 'Start On Date must be present') if start_on.blank?
      start_on_must_precede_end_on(start_on, end_on)
    end

    def presence_of_esi_details_if_esi
      return unless insurance_kind == 'employer_sponsored_insurance'
      errors.add(:employer_name, " ' EMPLOYER NAME' can't be blank ") if employer_name.blank?
      errors.add(:esi_covered, "' Who can be covered?' can't be blank ") if esi_covered.blank?
      errors.add(:start_on, "' Start On' Date can't be blank ") if start_on.blank?
      errors.add(:employer_id, "' EMPLOYER IDENTIFICATION NO.(EIN)' employer id can't be blank ") if !EnrollRegistry[:skip_employer_id_validation].enabled? && employer_id.blank?
      errors.add(:employee_cost_frequency, "' How Often' can't be blank ") if employee_cost_frequency.blank?
      errors.add(:employee_cost, "' AMOUNT' can't be blank ") if employee_cost.blank?
    end
  end
end
