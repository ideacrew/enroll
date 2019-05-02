class FinancialAssistance::Deduction
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :applicant, class_name: "::FinancialAssistance::Applicant"

  TITLE_SIZE_RANGE = 3..30
  FREQUENCY_KINDS = %W(biweekly daily half_yearly monthly quarterly weekly yearly)

  KINDS = %W(
      alimony_paid
      deductable_part_of_self_employment_taxes
      domestic_production_activities
      penalty_on_early_withdrawel_of_savings
      educator_expenses
      rent_or_royalties
      self_employment_sep_simple_and_qualified_plans
      self_employed_health_insurance
      student_loan_interest
      moving_expenses
      health_savings_account
      ira_deduction
      reservists_performing_artists_and_fee_basis_government_official_expenses
      tution_and_fees
    )

  field :title, type: String
  field :kind, as: :deduction_type, type: String, default: 'alimony_paid'
  field :amount, type: Money, default: 0.00
  field :start_on, type: Date
  field :end_on, type: Date
  field :frequency_kind, type: String
  field :submitted_at, type: DateTime

  field :workflow, type: Hash, default: { }
  validates_length_of :title,
                      in: TITLE_SIZE_RANGE,
                      allow_nil: true,
                      message: "pick a name length between #{TITLE_SIZE_RANGE}",
                      on: [:step_1, :submission]

  validates :amount,          presence: true,
                              numericality: { greater_than: 0, message: "%{value} must be greater than $0" },
                              on: [:step_1, :submission]
  validates :kind,            presence: true,
                              inclusion: { in: KINDS, message: "%{value} is not a valid deduction type" },
                              on: [:step_1, :submission]
  validates :frequency_kind,  presence: true,
                              inclusion: { in: FREQUENCY_KINDS, message: "%{value} is not a valid frequency" },
                              on: [:step_1, :submission]
  validates :start_on,        presence: true, on: [:step_1, :submission]

  validate :start_on_must_precede_end_on, on: [:step_1, :submission]

  before_create :set_submission_timestamp

  scope :of_kind, ->(deduction_kind) { where(kind: deduction_kind) }

private

  def set_submission_timestamp
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
  end

  def start_on_must_precede_end_on
    return unless start_on.present? && end_on.present?
    errors.add(:end_on, " End On date can't occur before Start On Date") if end_on < start_on
  end


end
