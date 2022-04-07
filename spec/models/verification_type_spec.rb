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
      EnrollRegistry[:indian_alaskan_tribe_details].feature.stub(:is_enabled).and_return(false)
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

    before do
      person.verification_types.each{|type| type.fail_type}
    end
    it "fail verification type" do
      expect(person.verification_types.all?{|type| type.is_type_outstanding?}).to be true
    end

    context 'when setting verification_document_due_in_days is enabled' do

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:set_due_date_upon_response_from_hub).and_return(true)
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
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:set_due_date_upon_response_from_hub).and_return(false)
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
      person.verification_types.each{|type| type.pass_type}
      expect(person.verification_types.all?{|type| type.type_verified?}).to be true
    end
    it "pending verification type" do
      person.verification_types.each{|type| type.pending_type}
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
    let!(:person10) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:ver_type10) do
      person10.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
      person10.verification_types.where(type_name: 'Citizenship').last
    end

    before do
      ver_type10.reject_type('Illegible')
    end

    it "should update verification_type's validation_status to rejected" do
      expect(ver_type10.validation_status).to eq('rejected')
    end

    it "should update verification_type's update_reason" do
      expect(ver_type10.update_reason).to eq('Illegible')
    end

    it "should update verification_type's rejected" do
      expect(ver_type10.rejected).to eq(true)
    end
  end
end
