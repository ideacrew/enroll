# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdMemberEnrollmentMember, type: :model do
  let!(:thhm_enrollment_member) { FactoryBot.build(:tax_household_member_enrollment_member)}
  let!(:thhe) {FactoryBot.create(:tax_household_enrollment, tax_household_members_enrollment_members: [thhm_enrollment_member])}

  context "#copy" do
    it 'should return attributes hash' do
      expect(thhm_enrollment_member.copy_attributes.class).to be Hash
    end
  end
end
