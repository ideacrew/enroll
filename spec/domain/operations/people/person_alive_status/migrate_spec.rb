# frozen_string_literal: true

# /Users/vishal/Documents/ideacrew/enroll/spec/domain/operations/people/person_alive_status/migrate_spec.rb

RSpec.describe Operations::People::PersonAliveStatus::Migrate, dbclean: :after_each do
  describe "#perform" do

    let(:person_with_consumer_role) { FactoryBot.create(:person, :with_consumer_role, ssn: "123456789")}
    let!(:family_1) { FactoryBot.create(:family, :with_primary_family_member, person: person_with_consumer_role) }

    let(:person_without_consumer_role) { FactoryBot.create(:person)}
    let!(:family_2) { FactoryBot.create(:family, :with_primary_family_member, person: person_without_consumer_role) }

    context "when alive status feature is enabled" do
      before do
        allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
      end

      it "should migrate person alive status" do
        expect(subject.call({person_hbx_id: person_with_consumer_role.hbx_id}).success).to eq("Successfully Migrated Person Alive Status")
        person_with_consumer_role.reload
        expect(person_with_consumer_role.demographics_group.persisted?).to eq(true)
        expect(person_with_consumer_role.demographics_group.alive_status.persisted?).to eq(true)
        expect(person_with_consumer_role.verification_types.alive_status_type.first.persisted?).to eq(true)
        expect(person_with_consumer_role.verification_types.alive_status_type.first.validation_status).to eq("unverified")
      end

      it "should migrate person alive status for person without consumer role" do
        expect(subject.call({person_hbx_id: person_without_consumer_role.hbx_id}).failure).to eq("Person does not have consumer role")
      end
    end

    context "when alive status feature is disabled" do
      before do
        allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(false)
      end

      it "should return a failure result with the error message" do
        expect(subject.call({person_hbx_id: person_with_consumer_role.hbx_id}).failure).to eq(["alive_status feature is disabled"])
      end
    end
  end
end