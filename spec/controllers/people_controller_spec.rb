require 'rails_helper'

RSpec.describe PeopleController do
  let(:census_employee_id) { "abcdefg" }
  let(:user) { FactoryGirl.build(:user) }
  let(:person) { FactoryGirl.build(:person) }
  let(:consumer_role){FactoryGirl.build(:consumer_role)}
  let(:vlp_document){FactoryGirl.build(:vlp_document)}

  it "GET new" do
    sign_in(user)
    get :new
    expect(response).to have_http_status(:success)
  end

  context "POST update" do
    let(:vlp_documents_attributes) { {"1" => vlp_document.attributes.to_hash}}
    let(:consumer_role_attributes) { consumer_role.attributes.to_hash}
    let(:person_attributes) { person.attributes.to_hash}
    let(:employee_roles) { person.employee_roles }
    let(:census_employee_id) {employee_roles[0].census_employee_id}


    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(Person).to receive(:where).and_return(Person)
      allow(Person).to receive(:first).and_return(person)
      allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(controller).to receive(:make_new_person_params).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)

      sign_in user
    end

    it "when individual" do
      allow(request).to receive(:referer).and_return("insured/families/personal")
      allow(person).to receive(:has_active_consumer_role?).and_return(true)
      allow(consumer_role).to receive(:find_document).and_return(vlp_document)
      allow(vlp_document).to receive(:save).and_return(true)
      allow(vlp_document).to receive(:update_attributes).and_return(true)

      consumer_role_attributes[:vlp_documents_attributes] = vlp_documents_attributes
      person_attributes[:consumer_role_attributes] = consumer_role_attributes

      post :update, id: person.id, person: person_attributes
      expect(response).to redirect_to(personal_insured_families_path)
      expect(assigns(:person)).not_to be_nil
      expect(flash[:notice]).to eq 'Person was successfully updated.'
    end

    
  end
end
