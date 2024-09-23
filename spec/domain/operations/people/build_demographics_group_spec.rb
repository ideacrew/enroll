# frozen_string_literal: true

require 'rails_helper'

# spec for testing Operations::People::BuildDemographicsGroup
describe Operations::People::BuildDemographicsGroup, dbclean: :after_each do
  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
  end

  context 'a user without a consumer_role' do
    let(:person) { FactoryBot.create(:person, :with_broker_role) }

    before do
      @result = described_class.new.call(person)
    end

    it 'returns a failure' do
      expect(@result.failure?).to be_truthy
      expect(@result.failure).to eq 'invalid consumer_role object'
    end

    it 'does not add a demographics group' do
      expect(person.demographics_group).to be_nil
    end
  end

  context 'a user with a consumer_role' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }

    context 'but without a demographics_group' do
      before do
        @result = described_class.new.call(person)
      end

      it 'returns success' do
        expect(@result.success?).to be_truthy
        expect(@result.success).to eq 'demographics_group and alive_status added to person'
      end

      it 'adds a demographics_group and an alive_status' do
        described_class.new.call(person)
        demographics_group = person.demographics_group

        expect(demographics_group).to be_instance_of DemographicsGroup
        expect(demographics_group.alive_status).to be_instance_of AliveStatus
      end
    end

    context 'with a demographics group but no alive_status' do
      before do
        person.update(demographics_group: DemographicsGroup.new)
        @result = described_class.new.call(person)
      end

      it 'returns success' do
        expect(@result.success?).to be_truthy
        expect(@result.success).to eq 'demographics_group and alive_status added to person'
      end

      it 'adds an alive_status to an existing demographics_group' do
        described_class.new.call(person)
        alive_status = person.demographics_group.alive_status

        expect(alive_status).to be_instance_of AliveStatus
      end
    end
  end
end
