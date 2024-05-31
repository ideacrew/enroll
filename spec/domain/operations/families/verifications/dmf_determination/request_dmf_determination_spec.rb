# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::RequestDmfDetermination, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:job) { FactoryBot.create(:transmittable_job, :dmf_determination) }

  let(:payload) do
    {
      family_hbx_id: family.hbx_assigned_id,
      job_id: job.job_id
    }
  end

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
  end

  context "failure" do
    it "should fail without a family_hbx_id" do
      payload[:family_hbx_id] = nil
      result = described_class.new.call(payload)

      expect(result).to be_failure
    end

    it "should fail without a job_id" do
      payload[:job_id] = nil
      result = described_class.new.call(payload)

      expect(result).to be_failure
    end

    it "should fail if a family can't be found" do
      payload[:family_hbx_id] = '12345'
      result = described_class.new.call(payload)

      expect(result).to be_failure
    end

    it "should fail if a transmittable job can't be found" do
      payload[:job_id] = '12345'
      result = described_class.new.call(payload)

      expect(result).to be_failure
    end
  end

  context "success" do
    before do
      @result = described_class.new.call(payload)
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should update the job" do
      expect(job.process_status.latest_state).to eq :transmitted
    end

    it "should create a transmission" do
      transmission = ::Transmittable::Transmission.where(key: :dmf_determination_request).last
      expect(transmission).to be_truthy
      expect(transmission.process_status.latest_state).to eq :succeeded
    end

    it "should create a transaction" do
      transaction = ::Transmittable::Transaction.where(key: :dmf_determination_request).last
      expect(transaction).to be_truthy
      expect(transaction.json_payload).to be_truthy
      expect(transaction.process_status.latest_state).to eq :succeeded
    end

    it 'family should have a transaction' do
      expect(family.transactions.count).to eq 1
    end
  end
end
