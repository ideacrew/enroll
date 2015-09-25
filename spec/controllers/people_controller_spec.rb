require 'rails_helper'

RSpec.describe PeopleController do
  let(:user) { FactoryGirl.build(:user) }
  let(:person) { FactoryGirl.build(:person) }

  it "GET new" do
    sign_in(user)
    get :new
    expect(response).to have_http_status(:success)
  end

  context "POST update" do
    let(:person_attributes) { person.attributes.to_hash }
    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(controller).to receive(:make_new_person_params).and_return(true)
      sign_in user
    end

    it "when individual" do
      allow(request).to receive(:referer).and_return("insured/families/personal")
      allow(person).to receive(:has_active_consumer_role?).and_return(true)
      post :update, id: person.id, person: person_attributes
      expect(response).to redirect_to(personal_insured_families_path)
      expect(flash[:notice]).to eq 'Person was successfully updated.'
    end

    it "when employee" do
      allow(person).to receive(:has_active_consumer_role?).and_return(false)
      post :update, id: person.id, person: person_attributes
      expect(response).to redirect_to(family_account_path)
      expect(flash[:notice]).to eq 'Person was successfully updated.'
    end
  end
end
