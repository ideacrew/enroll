# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::RequestDmfDetermination, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_ssn) }
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

  context "success for one member family" do
    before do
      job.create_process_status
      Operations::Eligibilities::BuildFamilyDetermination.new.call({effective_date: Date.today, family: family})
      family.eligibility_determination.subjects[0].eligibility_states.last.update(is_eligible: true)
      @result = described_class.new.call(payload)
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should create a verification type history element" do
      person.reload
      expect(person.alive_status.type_history_elements.count).to eq 1
      alive_status_element = person.alive_status.type_history_elements.last

      expect(alive_status_element.action).to eq 'DMF_Request_Submitted'
      expect(alive_status_element.modifier).to eq 'System'
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

  context "success for multi-member family" do
    let(:spouse_dob) { Date.today - 55.years }
    let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: 101_011_012) }
    let!(:spouse) { FactoryBot.create(:family_member, person: spouse_person, family: family) }

    before do
      job.create_process_status
      Operations::Eligibilities::BuildFamilyDetermination.new.call({effective_date: Date.today, family: family})
      family.eligibility_determination.subjects[0].eligibility_states.last.update(is_eligible: true)
      family.eligibility_determination.subjects[1].eligibility_states.last.update(is_eligible: true)
      @result = described_class.new.call(payload)
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should create a verification type history element for primary" do
      person.reload
      expect(person.alive_status.type_history_elements.count).to eq 1
      alive_status_element = person.alive_status.type_history_elements.last

      expect(alive_status_element.action).to eq 'DMF_Request_Submitted'
      expect(alive_status_element.modifier).to eq 'System'
    end

    it "should create a verification type history element for primary" do
      spouse_person.reload
      expect(spouse_person.alive_status.type_history_elements.count).to eq 1
      alive_status_element = spouse_person.alive_status.type_history_elements.last

      expect(alive_status_element.action).to eq 'DMF_Request_Submitted'
      expect(alive_status_element.modifier).to eq 'System'
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


  context "failure for all ineligible members" do
    let(:spouse_dob) { Date.today - 55.years }
    let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: 101_011_012) }
    let!(:spouse) { FactoryBot.create(:family_member, person: spouse_person, family: family) }

    before do
      job.create_process_status
      Operations::Eligibilities::BuildFamilyDetermination.new.call({effective_date: Date.today, family: family})
      family.eligibility_determination.subjects[0].eligibility_states.last.update(is_eligible: false)
      @result = described_class.new.call(payload)
    end

    it "should pass" do
      expect(@result).to be_failure
    end

    it "should create a verification type history element for primary" do
      person.reload
      expect(person.alive_status.type_history_elements.count).to eq 2
      request_submitted_history_elementt = person.alive_status.type_history_elements.first
      request_failed_history_element = person.alive_status.type_history_elements.last

      expect(request_submitted_history_elementt.action).to eq 'DMF_Request_Submitted'
      expect(request_submitted_history_elementt.modifier).to eq 'System'
      expect(request_failed_history_element.action).to eq 'DMF_Request_Failed'
      expect(request_failed_history_element.modifier).to eq 'System'
    end

    it "should create a verification type history element for spouse" do
      spouse_person.reload
      expect(spouse_person.alive_status.type_history_elements.count).to eq 2
      request_submitted_history_elementt = spouse_person.alive_status.type_history_elements.first
      request_failed_history_element = spouse_person.alive_status.type_history_elements.last

      expect(request_submitted_history_elementt.action).to eq 'DMF_Request_Submitted'
      expect(request_submitted_history_elementt.modifier).to eq 'System'
      expect(request_failed_history_element.action).to eq 'DMF_Request_Failed'
      expect(request_failed_history_element.modifier).to eq 'System'
    end

    it "should create a transmission" do
      transmission = ::Transmittable::Transmission.where(key: :dmf_determination_request).last
      expect(transmission).to be_truthy
      expect(transmission.process_status.latest_state).to eq :failed
    end

    it "should create a transaction" do
      transaction = ::Transmittable::Transaction.where(key: :dmf_determination_request).last
      expect(transaction).to be_truthy
      expect(transaction.json_payload).to be_nil
      expect(transaction.process_status.latest_state).to eq :failed
    end

    it 'family should have a transaction' do
      expect(family.transactions.count).to eq 1
    end
  end

  context "failure for some ineligible members" do
    let(:spouse_dob) { Date.today - 55.years }
    let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: 101_011_012) }
    let!(:spouse) { FactoryBot.create(:family_member, person: spouse_person, family: family) }

    before do
      job.create_process_status
      Operations::Eligibilities::BuildFamilyDetermination.new.call({effective_date: Date.today, family: family})
      family.eligibility_determination.subjects[0].eligibility_states.last.update(is_eligible: true)
      @result = described_class.new.call(payload)
    end

    it "should pass" do
      expect(@result).to be_success
    end

    it "should create a verification type history element for primary" do
      person.reload
      expect(person.alive_status.type_history_elements.count).to eq 1
      alive_status_element = person.alive_status.type_history_elements.last

      expect(alive_status_element.action).to eq 'DMF_Request_Submitted'
      expect(alive_status_element.modifier).to eq 'System'
    end

    it "should create a verification type history element for spouse" do
      spouse_person.reload
      expect(spouse_person.alive_status.type_history_elements.count).to eq 2
      request_submitted_history_elementt = spouse_person.alive_status.type_history_elements.first
      request_failed_history_element = spouse_person.alive_status.type_history_elements.last

      expect(request_submitted_history_elementt.action).to eq 'DMF_Request_Submitted'
      expect(request_submitted_history_elementt.modifier).to eq 'System'
      expect(request_failed_history_element.action).to eq 'DMF_Request_Failed'
      expect(request_failed_history_element.modifier).to eq 'System'
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
