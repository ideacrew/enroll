# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::RequestDmfDetermination, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  let(:job_payload) do
    {
      key: :dmf_determination,
      title: 'DMF Determination',
      description: 'Request for DMF Determination to fdsh gateway',
      correlation_id: family.hbx_assigned_id,
      started_at: DateTime.now,
      publish_on: DateTime.now
    }

    ::Operations::Transmittable::CreateJob.new.call(job_params)
  end

  let(:job) { FactoryBot.create(:transmittable_job, :dmf_determination, family_hbx_id: family.hbx_assigned_id) }

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
  end

  context "success" do
    before do
      @result = described_class.new.call(person)
    end

    it "should pass" do
      expect(@result).to be_success
    end
  end

  context "when use_transmittable is true" do
    before do
      allow(EnrollRegistry[:ssa_h3].setting(:use_transmittable)).to receive(:item).and_return(true)
      @result = described_class.new.call(person)
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should create a job" do
      expect(job.process_status.latest_state).to eq :transmitted
    end

    it "should create a transmission" do
      transmission = ::Transmittable::Transmission.where(key: :ssa_verification_request).last
      expect(transmission).to be_truthy
      expect(transmission.process_status.latest_state).to eq :succeeded
    end

    it "should create a transaction" do
      transaction = ::Transmittable::Transaction.where(key: :ssa_verification_request).last
      expect(transaction).to be_truthy
      expect(transaction.json_payload).to be_truthy
      expect(transaction.process_status.latest_state).to eq :succeeded
    end

    it 'person should have a transaction' do
      expect(person.transactions.count).to eq 1
    end
  end
end
