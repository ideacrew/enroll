# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VerificationType, :type => :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:local_residency) { EnrollRegistry[:enroll_app].setting(:state_residency).item }

  describe "verification_types creation" do
    it "creates types for person" do
      expect(person.verification_types.count).to be > 0
    end
  end

  describe "build certain type" do
    before do
      allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
    end
    context "SSN" do
      it "doesn't have ssn type" do
        person.ssn = nil
        person.save
        expect(person.consumer_role.verification_types.by_name("Social Security Number").first).to be nil
      end
      it "builds ssn type" do
        expect(person.consumer_role.verification_types.by_name("Social Security Number").first).not_to be nil
      end
    end
    context "local Residency" do
      it "builds local Residency type" do
        expect(person.consumer_role.verification_types.by_name(local_residency).first).not_to be nil
      end
    end
    context "American Indian Status" do
      it "build American Indian Status type" do
        person.tribal_id = "4848477"
        person.save
        expect(person.consumer_role.verification_types.by_name("American Indian Status").first).not_to be nil
      end
      it "doesn't build American Indian Status type" do
        person.tribal_id = nil
        person.save
        expect(person.consumer_role.verification_types.by_name("American Indian Status").first).to be nil
      end
    end
  end

  describe "type can be updated" do
    let(:due_date) { TimeKeeper.date_of_record + 96.days }

    context 'when not enrolled' do
      it "fail verification type" do
        person.verification_types.each(&:fail_type)
        expect(person.verification_types.all?(&:is_type_outstanding?)).to be false
        expect(person.verification_types.all?(&:is_type_negative_response_received?)).to be true
      end
    end

    context 'when enrolled' do
      let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role)}
      let(:family) { person.primary_family }
      let!(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_enrollment_members,
          enrollment_members: family.family_members,
          family: person.primary_family,
          kind: 'individual'
        )
      end

      it "fail verification type" do
        person.verification_types.each(&:fail_type)
        expect(person.verification_types.all?(&:is_type_outstanding?)).to be true
        expect(person.verification_types.all?(&:is_type_negative_response_received?)).to be false
      end
    end

    context 'when setting verification_document_due_in_days is enabled' do

      before do
        allow(EnrollRegistry[:set_due_date_upon_response_from_hub].feature).to receive(:is_enabled).and_return(true)
        person.verification_types.each(&:fail_type)
      end

      it "should set due date" do
        expect(person.reload.verification_types.all?{ |type| type.due_date == due_date }).to be_truthy
      end

      it "should set due date type" do
        expect(person.reload.verification_types.all?{ |type| type.due_date_type == 'response_from_hub' }).to be_truthy
      end
    end

    context 'when setting verification_document_due_in_days is disabled' do

      before do
        allow(EnrollRegistry[:set_due_date_upon_response_from_hub].feature).to receive(:is_enabled).and_return(false)
        person.verification_types.each(&:fail_type)
      end

      it "should not set due date" do
        expect(person.reload.verification_types.all?{ |type| type.due_date.nil? }).to be_truthy
      end

      it "should not set due date type" do
        expect(person.reload.verification_types.all?{ |type| type.due_date_type.nil? }).to be_truthy
      end
    end

    it "pass verification type" do
      person.verification_types.each(&:pass_type)
      expect(person.verification_types.all?(&:type_verified?)).to be true
    end
    it "pending verification type" do
      person.verification_types.each(&:pending_type)
      expect(person.verification_types.all?{|type| type.validation_status == "pending"}).to be true
    end

    context 'DC Residency' do
      before do
        @residency_verification_type = person.verification_types.by_name(local_residency).first
        @residency_verification_type.attest_type
        @history_track = @residency_verification_type.history_tracks.last
      end

      it 'attest verification type' do
        expect(@residency_verification_type.validation_status).to eq('attested')
      end

      it 'should update reason for verification type' do
        expect(@residency_verification_type.update_reason).to eq("Self Attest #{local_residency}")
      end

      it 'should add update_reason to history tracks' do
        expect(@history_track.modified.keys).to include('update_reason')
      end

      it 'should have update_reason as expected in history tracks' do
        expect(@history_track.modified['update_reason']).to eq("Self Attest #{local_residency}")
      end
    end
  end

  describe 'reject_type' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:verification_type) do
      person.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
    end

    before do
      verification_type.reject_type('Illegible')
    end

    it "should update verification_type" do
      expect(verification_type.validation_status).to eq('rejected')
      expect(verification_type.update_reason).to eq('Illegible')
      expect(verification_type.rejected).to eq(true)
    end
  end

  describe 'is_type_outstanding?' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:ver_type) { person.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified') }

    context 'for outstanding' do
      let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role)}
      let(:family) { person.primary_family }
      let!(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_enrollment_members,
          enrollment_members: family.family_members,
          family: person.primary_family,
          kind: 'individual'
        )
      end

      before { ver_type.fail_type }

      it 'should return true' do
        expect(ver_type.is_type_outstanding?).to eq(true)
      end

      it 'returns state as outstanding' do
        expect(ver_type.validation_status).to eq('outstanding')
      end
    end

    context 'for negative_response_received' do
      before { ver_type.fail_type }

      it 'should return true' do
        expect(ver_type.is_type_negative_response_received?).to eq(true)
      end

      it 'returns state as negative_response_received' do
        expect(ver_type.validation_status).to eq('negative_response_received')
      end
    end

    context 'for rejected' do
      before { ver_type.reject_type('Illegible') }

      it 'should return true' do
        expect(ver_type.is_type_outstanding?).to eq(true)
      end

      it 'return state as rejected' do
        expect(ver_type.validation_status).to eq('rejected')
      end
    end

    context 'for pass_type' do
      before { ver_type.pass_type }

      it 'should return false' do
        expect(ver_type.is_type_outstanding?).to eq(false)
      end

      it 'return state as verified' do
        expect(ver_type.validation_status).to eq('verified')
      end
    end
  end

  describe '#type_history_elements' do
    let(:alive_status) do
      person.add_new_verification_type(VerificationType::ALIVE_STATUS)
      person.alive_status
    end

    let(:type_history_params) do
      {
        action: 'Bulk response failed',
        modifier: 'System',
        update_reason: 'Bulk response failed due to some reason',
        saga_id: 'alive_status_verification',
        job_id: 'alive_status_verification_response_202405080953',
        transmission_id: 'alive_status_verification_transmission_response_202405080953',
        transaction_id: 'alive_status_verification_transaction_response_202405080953'
      }
    end

    let(:latest_type_history_element) do
      alive_status.fail_type
      alive_status.add_type_history_element(type_history_params)
      alive_status.type_history_elements.order(created_at: :desc).first
    end

    it 'returns job_id for type history element' do
      expect(latest_type_history_element.job_id).to eq(type_history_params[:job_id])
    end
  end
end
