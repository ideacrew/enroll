class FinancialAssistance::Benefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :applicant, class_name: "::FinancialAssistance::Applicant"

  TITLE_SIZE_RANGE = 3..30
  STATE_HEALTH_BENEFITS = %w(medicaid)

  KINDS = %W(
      acf_refugee_medical_assistance
      americorps_health_benefits
      child_health_insurance_plan
      medicaid
      medicare
      medicare_advantage
      medicare_part_b
      private_individual_and_family_coverage
      state_supplementary_payment
      tricare
      veterans_benefits
      naf_health_benefit_program
      health_care_for_peace_corp_volunteers
      state_supplementary_payment
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
    )

  field :title, type: String
  field :t_kind, type: String
  field :kind, type: String
  field :family_member_id, type: BSON::ObjectId

  field :is_employer_sponsored, type: Boolean
  field :is_eligible, type: Boolean
  field :is_enrolled, type: Boolean
  field :employee_cost, type: Money
  field :employee_cost_frequency, type: String

  field :enrolled_start_on, type: Date
  field :enrolled_end_on, type: Date
  field :eligible_start_on, type: Date
  field :eligible_end_on, type: Date
  field :submitted_at, type: DateTime

  field :workflow, type: Hash, default: { }

  field :employer_name, type: String
  field :employer_id, type: Integer
  
  embeds_one :employer_address, class_name: "::Address"
  embeds_one :employer_phone, class_name: "::Phone"
  # validates :start_on, presence: true

  validates_length_of :title, 
                      in: TITLE_SIZE_RANGE, 
                      allow_nil: true,
                      message: "pick a name length between #{TITLE_SIZE_RANGE}"

  # validates :kind,    presence: true, 
  #                     inclusion: { 
  #                       in: KINDS, 
  #                       message: "%{value} is not a valid alternative benefit type" 
  #                     }

  validate :presence_of_dates_if_enrolled, :presence_of_kind_if_eligible, :presence_of_esi_details_if_eligible_and_esi, :presence_of_dates_if_eligible

  before_create :set_submission_timestamp

  alias_method :is_employer_sponsored?, :is_employer_sponsored
  alias_method :is_eligible?, :is_eligible
  alias_method :is_enrolled?, :is_enrolled

  # Eligibility through public employee
  def is_state_health_benefit?
  end
  def family_member
    @family_member ||= FamilyMember.find(family_member_id)
  end

  def person
    @person ||= family_member.person
  end

private

  def set_submission_timestamp
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank? 
  end

  def start_on_must_precede_end_on(start_on, end_on)
    return unless start_on.present? && end_on.present?
    errors.add(:end_on, "can't occur before start on date") if end_on < start_on
  end

  def presence_of_dates_if_enrolled
    if is_enrolled
      errors.add(:enrolled_start_on, "If enrolled, must have start and end dates") if enrolled_start_on.blank? #&& enrolled_end_on.blank? End on not mandatory??
      start_on_must_precede_end_on(enrolled_start_on, enrolled_end_on)
    end
  end

  def presence_of_dates_if_eligible
    if is_eligible
      errors.add(:eligible_start_on, "If enrolled, must have start and end dates") if eligible_start_on.blank? #&& enrolled_end_on.blank? End on not mandatory??
      start_on_must_precede_end_on(eligible_start_on, eligible_end_on)
    end
  end

  def presence_of_kind_if_eligible
    if is_eligible
      errors.add(:kind, "If enrolled, must have a kind of health coverage") if kind.blank?
    end
  end

  def presence_of_esi_details_if_eligible_and_esi
    if is_eligible && kind == "employer_sponsored_insurance"
      errors.add(:employer_name, " can't be blank ") if employer_name.blank?
      errors.add(:t_kind, " can't be blank ") if t_kind.blank?
      errors.add(:eligible_start_on, " date can't be blank ") if eligible_start_on.blank?
      errors.add(:employer_id, " employer id can't be blank ") if employer_id.blank?
      errors.add(:employee_cost_frequency, " can't be blank ") if employee_cost_frequency.blank?
      errors.add(:employee_cost, " can't be blank ") if employee_cost.blank?

      if eligible_start_on.present? && eligible_end_on.present?
        start_on_must_precede_end_on(eligible_start_on, eligible_end_on)
      end
    end
  end
end