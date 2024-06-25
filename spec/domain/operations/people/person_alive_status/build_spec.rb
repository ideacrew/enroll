# frozen_string_literal: true

# /Users/vishal/Documents/ideacrew/enroll/spec/domain/operations/people/person_alive_status/build_spec.rb

RSpec.describe Operations::People::PersonAliveStatus::Build, dbclean: :after_each do
  describe "#perform" do

    let(:person_with_consumer_role) { FactoryBot.create(:person, :with_consumer_role, ssn: "123456789")}
    let!(:family_1) { FactoryBot.create(:family, :with_primary_family_member, person: person_with_consumer_role) }

    let(:person_without_consumer_role) { FactoryBot.create(:person)}
    let!(:family_2) { FactoryBot.create(:family, :with_primary_family_member, person: person_without_consumer_role) }

    context "with valid params" do
      before do
        allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
      end

      context 'for someone without an alive status demographics group or verification' do
        before do
          person_with_consumer_role.demographics_group.destroy
          person_with_consumer_role.verification_types.where(type_name: "Alive Status").first.destroy
        end

        it "should migrate person alive status" do
          expect(person_with_consumer_role.demographics_group).to be_nil
          # calling 'alive_status' directly on person obj returns alive_status verification
          expect(person_with_consumer_role.alive_status).to be_nil

          subject.new.call(person_with_consumer_role)
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