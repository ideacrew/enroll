# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Private::FamilyMemberCreated, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_ssn) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_member) { family.primary_family_member }

  describe 'Success' do
    let(:subject) { described_class.new }

    it 'returns success' do
      result = subject.call(family_member)

      expect(result.success?).to be_truthy
    end

    it 'returns success message' do
      result = described_class.new.call(family_member)
      expect(result.success).to eql("Successfully published 'events.families.created_or_updated' for family member with hbx_id: #{family_member&.person&.hbx_id}")
    end
  end

  describe 'Failure' do
    before do
      family.active_household.coverage_households.first.coverage_household_members.first.update_attributes(family_member_id: nil)
      family.reload
    end

    it 'returns failure when cv3 family fails' do
      result = described_class.new.call(family_member)
      expect(result.failure?).to be_truthy
    end
  end
end