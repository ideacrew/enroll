# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::BuildCv3FamilyPayloadForDmf, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:family) { FactoryBot.create(:individual_market_family_with_spouse) }
  let(:primary) { family.primary_person }
  let(:date) { DateTime.now }

  let(:job) do
    ::Operations::Transmittable::CreateJob.new.call(
      {
        key: :dmf_determination,
        title: 'Bulk DMF Determination call',
        description: "Job that requests begin coverage of all renewal IVL enrollments.",
        publish_on: date,
        started_at: date
      }
    ).success
  end

  let(:title) { "#{job.title} Request" }
  let(:description) { "#{job&.description}: individual call for family with hbx_id #{family.hbx_assigned_id}" }

  let(:transmission) do
    ::Operations::Transmittable::CreateTransmission.new.call(
      {
        job: job,
        key: :dmf_determination_request,
        title: title,
        description: description,
        correlation_id: family.hbx_assigned_id.to_s,
        publish_on: date,
        started_at: date,
        event: 'initial',
        state_key: :initial
      }
    ).success
  end

  let(:transaction) do
    ::Operations::Transmittable::CreateTransaction.new.call(
      {
        transmission: transmission,
        subject: family,
        key: :dmf_determination_request,
        title: title,
        description: description,
        correlation_id: family.hbx_assigned_id.to_s,
        publish_on: date,
        started_at: date,
        event: 'initial',
        state_key: :initial
      }
    ).success
  end

  let(:transmittable_params) {{ job: job, transmission: transmission, transaction: transaction }}

  # lambda to change member eligibility
  let(:change_member_eligibility) do
    lambda { |member_hbx_ids|
      subjects = family.eligibility_determination.subjects
      eligible_subjects = subjects.select { |sub| member_hbx_ids.include?(sub.hbx_id) }
      eligible_subjects.each do |subject|
        key = 'health_product_enrollment_status'
        state = subject.eligibility_states.where(eligibility_item_key: key).first
        state.update(is_eligible: true)
      end
    }
  end

  let(:dependent) { family.dependents.last.person }

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
    # need to run this operation to accurately handle cv3 family
    Operations::Eligibilities::BuildFamilyDetermination.new.call({ effective_date: Date.today, family: family })
  end

  context "success" do
    context 'with all valid members with an enrollment' do
      it "should pass" do
        # everyone subject is made eligible for enrollment
        all_member_ids = family.family_members.map(&:hbx_id)
        change_member_eligibility[all_member_ids]

        result = described_class.new.call(family, transmittable_params)
        expect(result).to be_success
      end
    end

    context 'with some non-enrolled members' do
      let(:check_eligibility_rules) { double(Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules) }

      before do
        # dependent subject is not made eligible for enrollment
        change_member_eligibility[primary.hbx_id]

        @result = described_class.new.call(family, transmittable_params)
      end

      it "should pass" do
        expect(@result).to be_success
      end

      it "should add type verification element to ineligible member verification" do
        dependent.reload
        element = dependent.alive_status.type_history_elements.last

        expect(element.action).to eq 'DMF Determination Request Failure'
        expect(element.update_reason).to eq "Family Member with hbx_id #{dependent.hbx_id} does not have a valid enrollment"
      end
    end

    context 'with some members with invalid ssns' do
      before do
        # everyone subject is made eligible for enrollment
        all_member_ids = family.family_members.map(&:hbx_id)
        change_member_eligibility[all_member_ids]

        dependent.update(ssn: '999999999')
        @result = described_class.new.call(family, transmittable_params)
      end

      it "should pass" do
        expect(@result).to be_success
      end

      it "should add type verification element to ineligible member verification" do
        dependent.reload
        element = dependent.alive_status.type_history_elements.last

        expect(element.action).to eq 'DMF Determination Request Failure'
        expect(element.update_reason).to eq "Family Member with hbx_id #{dependent.hbx_id} is not valid: [\"Invalid SSN\"]"
      end
    end
  end

  context "failure" do
    let(:fake_cv3_transformer) { double(Operations::Transformers::FamilyTo::Cv3Family) }

    context 'cv3 transformation failure' do
      before do
        allow(Operations::Transformers::FamilyTo::Cv3Family).to receive(:new).and_return(fake_cv3_transformer)
        allow(fake_cv3_transformer).to receive(:call).and_return(Failure('Unable to transform family into cv3_family'))

        @result = described_class.new.call(family, transmittable_params)
      end

      it 'should fail' do
        # no members have their subject changed to is_eligibile: true
        expect(@result).to be_failure
      end

      it 'should add a history element to all alive_status verifications' do
        alive_status_elements = [primary.alive_status, dependent.alive_status].map(&:type_history_elements)

        expect(alive_status_elements.all? { |elements| elements.last.update_reason.include?('Unable to transform family into cv3_family') }).to be_truthy
      end

      it "should update the transmission" do
        transmission.reload
        expect(transmission.process_status.latest_state).to eq :failed
        expect(transmission.transmittable_errors.size).to eq 1
        expect(transmission.transmittable_errors.last.message).to include('Unable to transform family into cv3_family')
      end

      it "should update the transaction" do
        transaction.reload
        expect(transaction.process_status.latest_state).to eq :failed
        expect(transaction.transmittable_errors.size).to eq 1
        expect(transaction.transmittable_errors.last.message).to include('Unable to transform family into cv3_family')
      end
    end

    context 'aca_entities validation failure' do
      before do
        allow(Operations::Transformers::FamilyTo::Cv3Family).to receive(:new).and_return(fake_cv3_transformer)
        allow(fake_cv3_transformer).to receive(:call).and_return(Success('success'))

        @result = described_class.new.call(family, transmittable_params)
      end

      it 'should fail' do
        # no members have their subject changed to is_eligibile: true
        expect(@result).to be_failure
      end

      it 'should add a history element to all alive_status verifications' do
        alive_status_elements = [primary.alive_status, dependent.alive_status].map(&:type_history_elements)

        expect(alive_status_elements.all? { |elements| elements.last.update_reason.include?('Invalid cv3 family') }).to be_truthy
      end

      it "should update the transmission" do
        transmission.reload
        expect(transmission.process_status.latest_state).to eq :failed
        expect(transmission.transmittable_errors.size).to eq 1
        expect(transmission.transmittable_errors.last.message).to include('Invalid cv3 family')
      end

      it "should update the transaction" do
        transaction.reload
        expect(transaction.process_status.latest_state).to eq :failed
        expect(transaction.transmittable_errors.size).to eq 1
        expect(transaction.transmittable_errors.last.message).to include('Invalid cv3 family')
      end
    end

    context 'with all members ineligible' do
      before do
        @result = described_class.new.call(family, transmittable_params)
      end

      it 'should fail' do
        # no members have their subject changed to is_eligibile: true
        expect(@result).to be_failure
      end

      it 'should add a history element to all alive_status verifications' do
        alive_status_elements = [primary.alive_status, dependent.alive_status].map(&:type_history_elements)

        expect(alive_status_elements.all? { |elements| elements.last.update_reason.include?('does not have a valid enrollment') }).to be_truthy
      end

      it "should update the transmission" do
        transmission.reload
        expect(transmission.process_status.latest_state).to eq :failed
        expect(transmission.transmittable_errors.size).to eq 1
        expect(transmission.transmittable_errors.last.message).to include('DMF Determination not sent: no family members are eligible')
      end

      it "should update the transaction" do
        transaction.reload
        expect(transaction.process_status.latest_state).to eq :failed
        expect(transaction.transmittable_errors.size).to eq 1
        expect(transaction.transmittable_errors.last.message).to include('DMF Determination not sent: no family members are eligible')
      end
    end
  end
end
