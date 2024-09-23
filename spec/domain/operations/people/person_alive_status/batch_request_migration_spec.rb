# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::People::PersonAliveStatus::BatchRequestMigration, dbclean: :after_each do
  include EventSource::Command
  include EventSource::Logging

  let(:person_with_consumer_role) { FactoryBot.create(:person, :with_consumer_role, ssn: '123456789')}
  let(:person_without_consumer_role) { FactoryBot.create(:person, ssn: '223456789')}
  let(:person_without_ssn) { FactoryBot.create(:person, :with_consumer_role, encrypted_ssn: nil)}

  context 'when people with and without consumer role exist' do
    let(:event) { Success(double) }
    let(:subject) do
      described_class.new
    end

    before do
      allow(subject).to receive(:event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
      person_with_consumer_role
      person_without_consumer_role
      person_without_ssn
      @result = subject.call
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end

    it 'should create a CSV file with the list of people with consumer role' do
      expect(File.exist?("alive_status_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv")).to be_truthy
    end

    it 'should return the number of people processed' do
      expect(@result.success).to match(/Successfully processed batch request for 1 people/)
    end
  end
end