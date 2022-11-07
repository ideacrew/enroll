# frozen_string_literal: true

class TaxHouseholdEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enrollment_id, type: BSON::ObjectId
  field :tax_household_id, type: BSON::ObjectId
  field :household_benchmark_ehb_premium, type: Money
  field :health_product_hios_id, type: String
  field :dental_product_hios_id, type: String
  field :household_health_benchmark_ehb_premium, type: Money
  field :household_dental_benchmark_ehb_premium, type: Money
  field :applied_aptc, type: Money
  field :available_max_aptc, type: Money

  embeds_many :tax_household_members_enrollment_members, class_name: "::TaxHouseholdMemberEnrollmentMember", cascade_callbacks: true

  def enrollment
    HbxEnrollment.find(enrollment_id)
  end

  def tax_household
    enrollment.family.tax_household_groups.flat_map(&:tax_households).detect{ |th| th.id.to_s == tax_household_id.to_s }
  end
end