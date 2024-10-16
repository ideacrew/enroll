# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insured::FamilyMembersController do
  let(:person) {FactoryBot.create(:person)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }

  let(:dependent) do
    instance_double(
      Forms::FamilyMember,
      addresses: [],
      same_with_primary: 'true',
      family_id: family.id,
      family_member: family_member
    )
  end
  let(:family_member) { family.family_members.where(:is_primary_applicant => false).first }
  let(:consumer_role) { FactoryBot.create(:consumer_role, person: person) }
  let!(:dependent_consumer_role) { FactoryBot.create(:consumer_role, person: family_member.person) }

  let(:dependent_controller_parameters) do
    ActionController::Parameters.new(dependent_update_properties).permit!
  end

  before(:each) do
    consumer_role.move_identity_documents_to_verified
    dependent_consumer_role.update!(is_applying_coverage: true)
    allow(dependent).to receive(:skip_consumer_role_callbacks=).with(true)
    sign_in(user)
  end

  describe "PUT update, for an IVL market dependent with a consumer role" do
    describe "when the value for 'is_applying_coverage' is provided" do
      let(:dependent_update_properties) do
        { "first_name" => "Dependent First Name", "same_with_primary" => "true", "is_applying_coverage" => "false" }
      end

      it "updates the 'is_applying_coverage' value for the dependent" do
        expect(dependent_consumer_role.is_applying_coverage).to eq true
        put :update, params: {id: family_member.id, dependent: dependent_update_properties}
        expect(dependent_consumer_role.is_applying_coverage).to eq true
      end
    end

    describe "when the value for 'is_applying_coverage' is NOT provided" do
      let(:dependent_update_properties) do
        { "first_name" => "Dependent First Name", "same_with_primary" => "true" }
      end

      it "does not change the 'is_applying_coverage' value for the dependent" do
        expect(dependent_consumer_role.is_applying_coverage).to eq true
        expect(dependent_consumer_role).not_to receive(:update_attribute)
        put :update, params: {id: family_member.id, dependent: dependent_update_properties}
        expect(dependent_consumer_role.is_applying_coverage).to eq true
      end
    end
  end

  context "PUT update, consumer not applying for coverage" do
    context "when the immigration fields are provided" do
      let(:dependent_update_properties) do
        {"first_name" => "Dependent First Name", "middle_name" => "", "last_name" => "test6", "name_sfx" => "", "dob" => "2024-10-01",
         "gender" => "male", "no_ssn" => "[FILTERED]", "is_applying_coverage" => "false",
         "relationship" => "child", "us_citizen" => "false", "eligible_immigration_status" => "true",
         "indian_tribe_member" => "true", "tribal_state" => "AZ", "tribe_codes" => [""], "tribal_name" => "6554bge", "is_incarcerated" => "false",
         "ethnicity" => ["", "", "", "", "", "", ""],
         "is_consumer_role" => "true", "same_with_primary" => "false",
         "addresses" => {"0" => {"kind" => "home", "_destroy" => "false", "address_1" => "123", "address_2" => "", "city" => "test",
                                 "state" => "AR", "zip" => "04001", "county" => "York"},
                         "1" => {"kind" => "mailing", "_destroy" => "false", "address_1" => "123", "address_2" => "", "city" => "mail", "state" => "AS",
                                 "zip" => "01578", "county" => "Zip code outside supported area"}}, "is_homeless" => "0", "family_id" => family.id}
      end

      it "should set consumer fields values to nil" do
        expect(dependent_consumer_role.is_applying_coverage).to eq true
        expect(dependent_consumer_role.is_incarcerated).to eq false
        put :update, params: {id: family_member.id, dependent: dependent_update_properties}
        dependent_consumer_role.person.reload
        dependent_consumer_role.reload
        expect(dependent_consumer_role.is_applying_coverage).to eq false
        expect(dependent_consumer_role.is_incarcerated).to eq nil
      end
    end
  end
end