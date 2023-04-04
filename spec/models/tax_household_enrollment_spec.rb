# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdEnrollment, type: :model do
  it { is_expected.to have_attributes(group_ehb_premium: nil) }

  context "#copy" do
    let!(:thhm_enrollment_member) { FactoryBot.build(:tax_household_member_enrollment_member)}
    let!(:thhe) {FactoryBot.create(:tax_household_enrollment, tax_household_members_enrollment_members: [thhm_enrollment_member])}

    it 'should return attributes hash when type is :attributes' do
      expect(thhe.copy.class).to be Hash
    end

    it 'should return object when type is :object' do
      expect(thhe.copy(:object).class).to be TaxHouseholdEnrollment
    end
  end
end
