# frozen_string_literal: true

class TaxHouseholdMemberEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_enrollment_member_id, type: BSON::ObjectId
  field :tax_household_member_id, type: BSON::ObjectId
  field :member_ehb_benchmark_health_premium, type: Money
  field :member_ehb_benchmark_health_premium, type: Money

end
