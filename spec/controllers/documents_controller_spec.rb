require 'rails_helper'

RSpec.describe DocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }


  describe "GET consumer role status" do

    it "renders index_consumer_role_status partial" do
      sign_in user
      get :consumer_role_status
      expect(response).to have_http_status(:success)
      expect(response).to render_template(partial: "documents/_index_consumer_role_status")
    end
  end

  describe "GET index" do
    it "renders index template" do
      sign_in user
      get :index, person_id: person.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template :index
    end

    it "assigns @person with person_id" do
      sign_in user
      get :index, person_id: person.id
      expect(assigns(:person)).to eq person
    end
  end

  describe "GET new comment" do
    it "renders new_comment template" do
      sign_in user
      get :new_comment, person_id: person.id, :format => 'js'
      expect(response).to have_http_status(:success)
      expect(response).to render_template :new_comment
    end

    it "assigns @person with person_id" do
      sign_in user
      get :new_comment, person_id: person.id, :format => 'js'
      expect(assigns(:person)).to eq person
    end
  end
end
