# frozen_string_literal: true

class TaxHouseholdMembersEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_enrollment_member_id, type: BSON::ObjectId
  field :tax_household_member_id, type: BSON::ObjectId

  embedded_in :tax_household_enrollment

end
