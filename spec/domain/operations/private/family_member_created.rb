# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Private::FamilyMemberCreated, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_ssn) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_member) { FactoryBot.create(:family_member, family: family, person: person) }

  describe 'Success' do
    let(:subject) { described_class.new }

    it 'returns success' do
      result = subject.call(family_member)

      expect(result.success?).to be_truthy
    end

    it 'returns success' do
      result = described_class.new.call(headers: headers, params: params)
      expect(result.success).to eql("Successfully published 'events.families.created_or_updated' for person with hbx_id: #{person.hbx_id}")
    end
  end

  describe 'Failure' do

    it 'returns failure' do
      result = described_class.new.call(headers: {}, params: {})

      expect(result.failure?).to be_truthy
    end
  end
end