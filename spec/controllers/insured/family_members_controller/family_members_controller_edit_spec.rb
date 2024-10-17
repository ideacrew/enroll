# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insured::FamilyMembersController do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:user) { FactoryBot.create(:user, person: person) }
  let!(:family){FactoryBot.create(:family,:with_primary_family_member, person: person)}
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family_member){FactoryBot.create(:family_member, family: family,is_primary_applicant: false, is_active: true, person: dependent_person)}
  let!(:dependent_consumer_role) { dependent_person.consumer_role }

  let(:dependent_controller_parameters) do
    ActionController::Parameters.new(dependent_update_properties).permit!
  end

  context "GET edit, consumer not applying for coverage" do
    context "when the immigration fields are present in DB" do
      let(:dependent_edit_properties) do
        {"bs4" => "true", "id" => family_member.id}
      end

      before(:each) do
        person.consumer_role.move_identity_documents_to_verified
        dependent_consumer_role.update!(is_applying_coverage: false)
        sign_in(user)
      end

      it "should set consumer fields values to nil" do
        expect(dependent_consumer_role.is_applying_coverage).to eq false
        expect(dependent_consumer_role.is_incarcerated).to eq false
        expect(dependent_consumer_role.citizen_status).to eq 'us_citizen'
        get :edit, params: dependent_edit_properties
        dependent_form = assigns(:dependent)
        expect(assigns(:dependent).family_member.person.consumer_role.is_applying_coverage).to eq false
        expect(dependent_form.is_incarcerated).to eq nil
        expect(dependent_form.citizen_status).to eq nil
      end
    end
  end
end