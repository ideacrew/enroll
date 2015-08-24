require 'rails_helper'

RSpec.describe Insured::FamiliesController do

  let(:hbx_enrollments) { double("HbxEnrollment") }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user) }
  let(:family) { double("Family") }
  let(:household) { double("HouseHold") }
  let(:family_members){[double("FamilyMember")]}
  let(:employee_roles) { [double("EmployeeRole")] }
  let(:consumer_role) { double("ConsumerRole") }

  before :each do 
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:primary_family).and_return(family)
    sign_in(user)
  end

  describe "GET home" do
    before :each do 
      allow(family).to receive(:latest_household).and_return(household)
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:active).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:coverage_selected).and_return(hbx_enrollments)
    end

    context "for SHOP market" do    
      before :each do
        allow(person).to receive(:employee_roles).and_return(employee_roles)
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to eq(employee_roles[0])
      end

      it "should get shop market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.shop_market_events
      end
    end

    context "for IVL market" do    
      before :each do
        allow(person).to receive(:employee_roles).and_return([])
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to be_nil
      end

      it "should get individual market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.individual_market_events
      end
    end
  end

  describe "GET manage_family" do
    before :each do 
      allow(family).to receive(:active_family_members).and_return(family_members)
      get :manage_family
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render manage family section" do
      expect(response).to render_template("manage_family")
    end

    it "should assign variables" do
      expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
      expect(assigns(:family_members)).to eq(family_members)
    end
  end

  describe "GET personal" do
    before :each do 
      allow(family).to receive(:active_family_members).and_return(family_members)
      get :personal
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render person edit page" do
      expect(response).to render_template("personal")
    end

    it "should assign variables" do
      expect(assigns(:family_members)).to eq(family_members)
    end
  end

  describe "GET inbox" do
    before :each do 
      get :inbox
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render inbox" do
      expect(response).to render_template("inbox")
    end

    it "should assign variables" do
      expect(assigns(:folder)).to eq("Inbox")
    end
  end


  describe "GET document_index" do
    before :each do 
      get :documents_index
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render document index page" do
      expect(response).to render_template("documents_index")
    end
  end


  describe "GET document_upload" do
    before :each do 
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      get :document_upload
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render document upload page" do
      expect(response).to render_template("document_upload")
    end

    it "should assign variables" do
      expect(assigns(:consumer_wrapper)).to be_an_instance_of(Forms::ConsumerRole)
    end
  end
end
