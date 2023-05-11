# frozen_string_literal: true

class TaxHouseholdMemberEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_enrollment_member_id, type: BSON::ObjectId
  field :tax_household_member_id, type: BSON::ObjectId
  field :age_on_effective_date, type: Integer
  field :family_member_id, type: BSON::ObjectId
  field :relationship_with_primary, type: String
  field :date_of_birth, type: Date

  embedded_in :tax_household_enrollment, class_name: "::TaxHouseholdEnrollment"

  def copy_attributes
    {hbx_enrollment_member_id: hbx_enrollment_member_id,
     tax_household_member_id: tax_household_member_id,
     age_on_effective_date: age_on_effective_date,
     family_member_id: family_member_id,
     relationship_with_primary: relationship_with_primary,
     date_of_birth: date_of_birth}
  end

  def hbx_enrollment_member
    tax_household_enrollment.tax_household.tax_household_members.find(hbx_enrollment_member_id)
  end

  def tax_household_member
    tax_household_enrollment.enrollment.hbx_enrollment_members.find(tax_household_member_id)
  end
end
