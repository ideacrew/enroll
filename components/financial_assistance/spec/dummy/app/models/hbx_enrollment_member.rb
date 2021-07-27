# frozen_string_literal: true

# rubocop:disable all

class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include BelongsToFamilyMember
  include Insured::GroupSelectionHelper
  include Insured::EmployeeRolesHelper
  include ApplicationHelper

  embedded_in :hbx_enrollment

  field :applicant_id, type: BSON::ObjectId
  field :carrier_member_id, type: String
  field :is_subscriber, type: Boolean, default: false

  field :premium_amount, type: Money
  field :applied_aptc_amount, type: Money, default: 0.0

  field :eligibility_date, type: Date
  field :coverage_start_on, type: Date
  field :coverage_end_on, type: Date

  validates_presence_of :applicant_id, :is_subscriber, :eligibility_date, # :premium_amount,
                        :coverage_start_on

  validate :check_primary_applicant_selected_during_enrollment

  validate :end_date_gt_start_date

  delegate :ivl_coverage_selected, :is_disabled, to: :family_member

  def family
    hbx_enrollment.family if hbx_enrollment.present?
  end

  def covered?
    coverage_end_on.blank? || coverage_end_on >= TimeKeeper.date_of_record ? true : false
  end

  def family_member
    self.hbx_enrollment.family.family_members.detect do |fm|
      fm.id == applicant_id
    end
  end

  def primary_relationship
    return @primary_relationship unless @primary_relationship.blank?
    @primary_relationship = family_member.primary_relationship
  end

  def hbx_id
    person.hbx_id
  end

  def <=>(other)
    [hbx_id, is_subscriber, coverage_start_on] <=> [other.hbx_id, other.is_subscriber, other.coverage_start_on]
  end

  def person
    return @person unless @person.blank?
    @person = family_member.person
  end

  def age_on_effective_date
    return @age_on_effective_date unless @age_on_effective_date.blank?
    dob = person.dob
    return unless coverage_start_on.present?

    age = calculate_age(coverage_start_on,dob)
    @age_on_effective_date = age
  end

  def calculate_age(calculation_date,dob)
    age = calculation_date.year - dob.year

    # Shave off one year if the calculation date is before the birthday.
    if calculation_date.month == dob.month
      age -= 1 if calculation_date.day < dob.day
    else
      age -= 1 if calculation_date.month < dob.month
    end
    age
  end

  def is_subscriber?
    self.is_subscriber
  end

  def self.new_from(coverage_household_member:)
    new(
      applicant_id: coverage_household_member.family_member_id,
      is_subscriber: coverage_household_member.is_subscriber
    )
  end

  def is_covered_on?(coverage_date)
    if coverage_end_on.present? && coverage_end_on < coverage_date
      false
    else
      true
    end
  end

  def valid_enrolling_member?
    return true unless self.hbx_enrollment.employee_role.present?

    health_relationship_benefits, dental_relationship_benefits = shop_health_and_dental_relationship_benefits(hbx_enrollment.employee_role, hbx_enrollment.benefit_group)
    if hbx_enrollment.coverage_kind == 'health'
      return false unless coverage_relationship_check(health_relationship_benefits, family_member, hbx_enrollment.benefit_group.effective_on_for(hbx_enrollment.employee_role.hired_on))
    else
      return false unless coverage_relationship_check(dental_relationship_benefits, family_member, hbx_enrollment.benefit_group.effective_on_for(hbx_enrollment.employee_role.hired_on))
    end
    true
  end

  private

  def end_date_gt_start_date
    return unless coverage_end_on.present?
    self.errors.add(:coverage_end_on, "Coverage start date must preceed or equal end date") if coverage_end_on < coverage_start_on
  end

  def check_primary_applicant_selected_during_enrollment
    return true #FixMe
    self.errors.add(:is_subscriber, "You must select the primary applicant to enroll in the healthcare plan.") if self.hbx_enrollment.subscriber.nil?
  end
end

# rubocop:enable all
