require 'rails_helper'

RSpec.describe DocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:consumer_role) {FactoryGirl.build(:consumer_role)}
  let(:document) {FactoryGirl.build(:vlp_document)}
  let(:family)  {FactoryGirl.create(:family, :with_primary_family_member)}
  let(:lawful_presence_determination) { FactoryGirl.build(:lawful_presence_determination)}

  before :each do
    sign_in user
  end

  describe "PUT update individual" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    it "redirect_to back" do
      post :update_individual, person_id: person.id
      expect(response).to redirect_to :back
    end

    it "transfers the current state" do
      post :update_individual, person_id: person.id
      person.reload
      expect(person.consumer_role.aasm_state).to eq("fully_verified")
    end
  end

  describe "destroy" do
    before :each do
      person.consumer_role.vlp_documents = [document]
      delete :destroy, person_id: person.id, id: document.id
    end
    it "redirects_to verification page" do
      expect(response).to redirect_to verification_insured_families_path
    end

    it "should delete document record" do
      person.reload
      expect(person.consumer_role.vlp_documents).to be_empty
    end
  end

  describe "PUT update" do
    context "rejecting with comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :person=>{ :vlp_document=>{:comment=>"hghghg"}}, :comment => true, :status => "ready"
        document.reload
        expect(document.status).to eq("ready")
      end
    end

    context "accepting without comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :status => "accept"
        document.reload
        expect(document.status).to eq("accept")
      end
    end
  end
  describe "PUT extend due date" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      put :extend_due_date, person_id: person.id
    end

    it "should redirect to back" do
      expect(response).to redirect_to :back
    end

    context "with denied documents by FedHub response" do
      it "creates special verification period" do
        allow(lawful_presence_determination).to receive(:latest_denial_date).and_return(TimeKeeper.date_of_record)
        person.consumer_role.lawful_presence_determination = lawful_presence_determination
        person.reload
        expect(person.consumer_role.special_verification_period).to eq(TimeKeeper.date_of_record + 120.days)
      end
    end

    context "without FedHub response" do
      it "creates special verification period with 30 days delay" do
        person.reload
        expect(person.consumer_role.special_verification_period).to eq(TimeKeeper.date_of_record + 120.days)
      end
    end

    context "person has special verification period" do
      it "extend existing special verification period to 30 days" do
        person.consumer_role.special_verification_period = TimeKeeper.date_of_record
        person.save
        put :extend_due_date, person_id: person.id
        person.reload
        expect(person.consumer_role.special_verification_period).to eq(TimeKeeper.date_of_record + 30.days)
      end
    end
  end
end
