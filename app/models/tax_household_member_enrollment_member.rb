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

end
