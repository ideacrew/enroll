# frozen_string_literal: true

# A model for a member which has information about their premium credit.
# Each Member Premium Credit is associated with {FamilyMember}

# For Individual context:
#   A member which has information about their financial assistance eligibility like Insurance Assistance or Medicaid.
class MemberPremiumCredit
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %w[aptc_eligible csr].freeze

  APTC_VALUES = %w[true false].freeze
  CSR_VALUES = %w[100 94 87 73 0 limited].freeze

  # Fields
  field :kind, type: String

  # Value can be of any data type that is converted to String
  # For IVL context,
  #   value can be 'true' if kind is 'aptc_eligible'
  #   value can be '87' if kind is 'csr'
  field :value, type: String

  # Effective Period of MemberPremiumCredit.
  # These values should always match with GroupPremiumCredit's start_on and end_on
  field :start_on, type: Date
  field :end_on, type: Date

  field :family_member_id, type: BSON::ObjectId

  # Associations
  embedded_in :group_premium_credit

  # TODO: Review scopes
  # Scopes
  scope :aptc_eligible, -> { where(kind: 'aptc_eligible', value: 'true') }
  scope :csr_eligible, -> { where(kind: 'csr', :value.in => (CSR_VALUES - ['0'])) }

  # Validations
  validates_presence_of :start_on

  validates :kind,
            inclusion: { in: KINDS, message: "%{value} is not a valid member premium credit kind" },
            allow_blank: false

  validate :validate_dates
  validate :validate_value

  def family_member
    FamilyMember.find(family_member_id.to_s)
  end

  private

  def validate_value
    case kind
    when 'aptc_eligible'
      return if APTC_VALUES.include?(value)
      errors.add(:base, "value: #{value} is not a valid value for kind: aptc_eligible, should be one of #{APTC_VALUES}")
    when 'csr'
      return if CSR_VALUES.include?(value)
      errors.add(:base, "value: #{value} is not a valid value for kind: csr, should be one of #{CSR_VALUES}")
    end
  end

  def validate_dates
    return unless end_on.present? && start_on > end_on

    errors.add(:base, "end_on: #{end_on} cannot occur before start_on: #{start_on}")
  end
end
