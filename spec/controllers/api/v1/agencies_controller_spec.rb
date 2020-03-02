require 'rails_helper'

RSpec.describe Api::V1::AgenciesController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "#index" do
    before :each do
      sign_in(user)
      get :index
    end

    it "is successful" do
      expect(response.status).to eq 200
    end
  end

  describe "GET #primary_agency_staff, with no records" do
    before :each do
      sign_in(user)
      get :primary_agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has and empty json response" do
      expect(response.body).to eq("[]")
    end
  end

  describe "GET #primary_agency_staff, with a broker" do
    let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: "active") }

    before :each do
      broker_role
      sign_in(user)
      get :primary_agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has no records" do
      expect(response.body).not_to eq("[]")
    end
  end

  describe "GET #primary_agency_staff, with a ga staff" do
    let(:general_staff_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: "active", is_primary: true)}
    before :each do
      general_staff_role
      sign_in(user)
      get :primary_agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has no records" do
      expect(response.body).not_to eq("[]")
    end
  end

  describe "GET #agency_staff, with no records" do
    before :each do
      sign_in(user)
      get :agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has and empty json response" do
      expect(response.body).to eq("[]")
    end
  end

  describe "GET #agency_staff, with a broker_agency_staff" do
    let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
    let(:broker_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency.id) }

    before :each do
      broker_role
      sign_in(user)
      get :agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has no records" do
      expect(response.body).not_to eq("[]")
    end
  end

  describe "GET #agency_staff, with a ga staff" do
    let(:general_staff_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: "active", is_primary: false)}
    before :each do
      general_staff_role
      sign_in(user)
      get :agency_staff
    end

    it "is successful" do
      expect(response.status).to eq(200)
    end

    it "has no records" do
      expect(response.body).not_to eq("[]")
    end
  end
end
