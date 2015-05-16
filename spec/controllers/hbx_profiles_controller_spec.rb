require 'rails_helper'

RSpec.describe HbxProfilesController, :type => :controller do

  describe "GET welcome" do
    it "returns http success" do
      get :welcome
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET create" do
    it "returns http success" do
      get :create
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET update" do
    it "returns http success" do
      get :update
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET employer_index" do
    it "returns http success" do
      get :employer_index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET broker_agency_index" do
    it "returns http success" do
      get :broker_agency_index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET insured_index" do
    it "returns http success" do
      get :insured_index
      expect(response).to have_http_status(:success)
    end
  end

end
