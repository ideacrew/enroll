# frozen_string_literal: true

module FinancialAssistance
  class Income
    include Mongoid::Document
    include Mongoid::Timestamps

    before_create :set_submission_timestamp
    after_save :update_applicant_income

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'
    embeds_one :employer_address, class_name: 'FinancialAssistance::Locations::Address', validate: (EnrollRegistry[:skip_employer_address_validation].enabled? ? false : true), cascade_callbacks: true
    embeds_one :employer_phone, class_name: 'FinancialAssistance::Locations::Phone', validate: (EnrollRegistry[:skip_employer_phone_validation].enabled? ? false : true), cascade_callbacks: true

    TITLE_SIZE_RANGE = (3..30).freeze
    EXCLUDED_PARAMS = %w[_id created_at updated_at employer_address employer_phone].freeze

    KINDS = %w[
      alimony_and_maintenance
      american_indian_and_alaskan_native
      capital_gains
      dividend
      employer_funded_disability
      estate_trust
      farming_and_fishing
      foreign
      interest
      lump_sum_amount
      military
      net_self_employment
      other
      pension_retirement_benefits
      permanent_workers_compensation
      prizes_and_awards
      rental_and_royalty
      scholarship_payments
      social_security_benefit
      supplemental_security_income
      tax_exempt_interest
      unemployment_income
      wages_and_salaries
      income_from_irs
    ].freeze

    # These are used specifically in the process of constructing the payload for us to send this to MedicaidGateway(including Mitc)
    EARNED_INCOME_KINDS = %w[wages_and_salaries net_self_employment scholarship_payments].freeze
    UNEARNED_INCOME_KINDS = (KINDS - EARNED_INCOME_KINDS).freeze

    JOB_INCOME_TYPE_KIND = 'wages_and_salaries'
    NET_SELF_EMPLOYMENT_INCOME_KIND = 'net_self_employment'
    UNEMPLOYMENT_INCOME_KIND = 'unemployment_income'
    FREQUENCY_KINDS = %w[biweekly daily half_yearly monthly quarterly weekly yearly].freeze

    NEGATIVE_AMOUNT_INCOME_TYPE_KINDS = EnrollRegistry[:negative_amount_income_types].setting(:income_types).item || %w[net_self_employment capital_gains farming_and_fishing].freeze

    OTHER_INCOME_TYPE_KIND = {
      alimony_and_maintenance: 'Alimony received',
      capital_gains: 'Capital gains',
      dividend: 'Dividends',
      interest: 'Interest',
      pension_retirement_benefits: 'Pension or retirement',
      rental_and_royalty: 'Rent and royalties',
      social_security_benefit: 'Social Security',
      employer_funded_disability: 'Employer-funded disability payments',
      estate_trust: 'Estate and trust',
      farming_and_fishing: 'Farming or fishing',
      foreign: 'Foreign income',
      other: 'Other taxable income',
      prizes_and_awards: FinancialAssistanceRegistry[:prize_and_awards].setting(:gamble_prize).item ? 'Gambling, prizes or awards' : 'Prizes and awards',
      scholarship_payments: 'Taxable scholarship payments'
    }

    OTHER_INCOME_TYPE_KIND.merge!(american_indian_and_alaskan_native: "American Indian/Alaska Native income") unless EnrollRegistry.feature_enabled?(:american_indian_alaskan_native_income)
    OTHER_INCOME_TYPE_KIND.freeze

    ALL_INCOME_KINDS_MAPPED = OTHER_INCOME_TYPE_KIND.merge(
      JOB_INCOME_TYPE_KIND.to_sym => 'Wages and Salaries',
      NET_SELF_EMPLOYMENT_INCOME_KIND.to_sym => 'Net Self Employment',
      UNEMPLOYMENT_INCOME_KIND.to_sym => 'Unemployment Income',
      'deductable_part_of_self_employment_taxes'.to_sym => 'Deductible Part of Self Employment Taxes'
    )

    field :title, type: String
    field :kind, as: :income_type, type: String, default: 'wages_and_salaries'
    field :wage_type, type: String
    field :hours_per_week, type: Integer
    field :amount, type: Money, default: 0.00
    field :amount_tax_exempt, type: Integer, default: 0
    field :frequency_kind, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :is_projected, type: Boolean, default: false
    field :tax_form, type: String
    field :employer_name, type: String
    field :employer_id, type: Integer
    field :has_property_usage_rights, type: Boolean
    field :submitted_at, type: DateTime
    field :workflow, type: Hash, default: { }

    scope :jobs, -> {where(kind: JOB_INCOME_TYPE_KIND)}
    scope :self_employment, -> {where(kind: NET_SELF_EMPLOYMENT_INCOME_KIND)}
    scope :other, -> {where(:kind.nin => [JOB_INCOME_TYPE_KIND, NET_SELF_EMPLOYMENT_INCOME_KIND, UNEMPLOYMENT_INCOME_KIND])}
    scope :of_kind, ->(kind) {where(kind: kind)}
    scope :unemployment, ->{where(kind: 'unemployment_income')}
    scope :american_indian_and_alaskan_native, ->{where(kind: 'american_indian_and_alaskan_native')}

    validates_length_of :title,
                        in: TITLE_SIZE_RANGE,
                        allow_nil: true,
                        message: "pick a name length between #{TITLE_SIZE_RANGE}",
                        on: [:step_1, :submission]

    validates :amount, presence: true,
                       numericality: {
                         greater_than: 0, message: "%{value} must be greater than $0"
                       },
                       on: [:step_1, :submission], unless: :income_amount_validate

    validates :kind, presence: true,
                     inclusion: {
                       in: KINDS, message: "%{value} is not a valid income type"
                     },
                     on: [:step_1, :submission]

    validates :frequency_kind, presence: true,
                               inclusion: {
                                 in: FREQUENCY_KINDS, message: "%{value} is not a valid frequency"
                               }

    validates :start_on, presence: true, on: [:step_1, :submission]
    validate :start_on_must_precede_end_on
    validate :check_if_valid_amount

    def hours_worked_per_week
      return 0 if end_on.blank? || end_on > TimeKeeper.date_of_record
      hours_per_week || 0
    end

    def same_as?(other)
      amount == other.amount \
        && kind == other.kind \
        && frequency == other.frequency \
        && start_on == other.start_on \
        && end_on == other.end_on \
        && is_projected == other.is_projected \
        && submitted_at == other.submitted_at
    end

    def negative_income_accepted?
      NEGATIVE_AMOUNT_INCOME_TYPE_KINDS.include?(kind)
    end

    def skip_zero_income_amount_validation
      FinancialAssistanceRegistry.feature_enabled?(:skip_zero_income_amount_validation)
    end

    def income_amount_validate
      (negative_income_accepted? || skip_zero_income_amount_validation)
    end


    def <=>(other)
      [amount, kind, frequency, start_on, end_on, is_projected] ==
        [other.amount, other.kind, other.frequency, other.start_on, other.end_on, other.is_projected]
    end

    def self.from_income_request(income_data)
      Income.new(
        amount: (income_data[:amount] * 100).to_i,
        kind: income_data[:kind],
        frequency: income_data[:frequency],
        start_on: income_data[:start_on],
        end_on: income_data[:end_on],
        is_projected: income_data[:is_projected],
        submitted_at: income_data[:submitted_at]
      )
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
        applications = ::FinancialAssistance::Application.where('applicants.incomes._id' => bson_id)
        return unless applications.size == 1
        applicants = applications.first.applicants.where('incomes._id' => bson_id)
        applicants.size == 1 ? applicants.first.incomes.find(bson_id) : nil
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def calculate_annual_income
      case frequency_kind.downcase
      when 'weekly'
        amount * 52
      when 'monthly'
        amount * 12
      when 'yearly'
        amount
      when 'biweekly'
        amount * 26
      when 'quarterly'
        amount * 4
      when 'daily'
        amount * 5 * 52
      else
        0
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    private

    def update_applicant_income
      FinancialAssistance::Operations::Applicant::CalculateAndPersistNetAnnualIncome.new.call({application_assistance_year: _parent.application.assistance_year, applicant: _parent}) if _parent.present? && self.valid?(:submission)
    end

    def set_submission_timestamp
      write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
    end

    def start_on_must_precede_end_on
      return unless start_on.present? && end_on.present?
      errors.add(:end_on, "Date can't occur before start on date") if end_on < start_on
    end

    def check_if_valid_amount
      return if negative_income_accepted?

      errors.add(:amount, "$#{amount} must be greater than $0.") if amount.to_f < 0
    end
  end
end
