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

  # applied_aptc is the amount of aptc that is consumed from the TaxHousehold for a given HbxEnrollment
  field :applied_aptc, type: Money

  field :available_max_aptc, type: Money

  # group_ehb_premium is sum of ehb_premiums of APTC eligible TaxHouseholdMembers associated with :tax_household_id who are enrolled in HbxEnrollment(enrollment_id).
  #   For Example:
  #     Enrollment1: A, B, C, D
  #     TaxHousehold1: A, C
  #     TaxHousehold2: B, D
  #     For a given TaxHouseholdEnrollment(enrollment_id: Enrollment1.id, tax_household_id: TaxHousehold1.id),
  #       the :group_ehb_premium is sum of ehb_premiums of A and C
  field :group_ehb_premium, type: Money

  # Scopes
  scope :by_enrollment_id, ->(enrollment_id) { where(enrollment_id: enrollment_id) }

  embeds_many :tax_household_members_enrollment_members, class_name: "::TaxHouseholdMemberEnrollmentMember", cascade_callbacks: true

  index({"enrollment_id" => 1})
  index({"tax_household_id" => 1})

  def enrollment
    HbxEnrollment.find(enrollment_id)
  end

  def tax_household
    enrollment.family.tax_household_groups.flat_map(&:tax_households).detect{ |th| th.id.to_s == tax_household_id.to_s }
  end

  def build_tax_household_enrollment_for(hbx_enrollment)
    new_thhe_attributes = self.copy_attributes
    new_thhm_enrollment_members = new_thhe_attributes[:tax_household_members_enrollment_members]

    hbx_enrollment.hbx_enrollment_members.each do |enrollment_member|
      new_thhm_enrollment_member = new_thhm_enrollment_members.select{|thhm_enrollment_member| thhm_enrollment_member[:family_member_id].to_s == enrollment_member.applicant_id.to_s}&.first
      next unless new_thhm_enrollment_member
      new_thhm_enrollment_member[:hbx_enrollment_member_id] = enrollment_member.id
    end

    new_thhe_attributes[:enrollment_id] = hbx_enrollment.id
    self.class.new(new_thhe_attributes)
  end

  def copy_attributes
    thhm_enrollment_members = tax_household_members_enrollment_members.collect(&:copy_attributes)

    {
      enrollment_id: enrollment_id,
      tax_household_id: tax_household_id,
      household_benchmark_ehb_premium: household_benchmark_ehb_premium&.to_d,
      health_product_hios_id: health_product_hios_id,
      dental_product_hios_id: dental_product_hios_id,
      household_health_benchmark_ehb_premium: household_health_benchmark_ehb_premium&.to_d,
      household_dental_benchmark_ehb_premium: household_dental_benchmark_ehb_premium&.to_d,
      applied_aptc: applied_aptc&.to_d,
      available_max_aptc: available_max_aptc&.to_d,
      group_ehb_premium: group_ehb_premium&.to_d,
      tax_household_members_enrollment_members: thhm_enrollment_members
    }
  end
end
