require 'rails_helper'

RSpec.describe Insured::FamiliesController do

  let(:hbx_enrollments) { double("HbxEnrollment") }
  let(:user) { double("User", last_portal_visited: "test.com") }
  let(:person) { double("Person", id: "test") }
  let(:family) { double("Family") }
  let(:household) { double("HouseHold") }
  let(:family_members){[double("FamilyMember")]}
  let(:employee_roles) { [double("EmployeeRole")] }
  let(:consumer_role) { double("ConsumerRole") }

  before :each do
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:primary_family).and_return(family)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(person).to receive(:employee_roles).and_return(employee_roles)
    sign_in(user)
  end

  describe "GET home" do
    before :each do
      allow(family).to receive(:enrolled_hbx_enrollments).and_return(hbx_enrollments)
      allow(user).to receive(:has_employee_role?).and_return(true)
      allow(user).to receive(:has_consumer_role?).and_return(true)
      allow(user).to receive(:last_portal_visited=).and_return("test.com")
      allow(user).to receive(:save).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      session[:portal] = "insured/families"
    end

    context "for SHOP market" do
      before :each do
        sign_in user
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
      allow(person).to receive(:employee_roles).and_return(employee_roles)
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

  describe "GET find_sep" do
    before :each do
      get :find_sep, hbx_enrollment_id: "2312121212", change_plan: "change_plan"
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render my account page" do
      expect(response).to render_template("find_sep")
    end

    it "should assign variables" do
      expect(assigns(:hbx_enrollment_id)).to eq("2312121212")
      expect(assigns(:change_plan)).to eq('change_plan')
    end
  end

  describe "POST record_sep" do
    before :each do
      @qle = FactoryGirl.create(:qualifying_life_event_kind)
      @family = FactoryGirl.build(:family, :with_primary_family_member)
      allow(person).to receive(:primary_family).and_return(@family)
    end

    context 'when its initial enrollment' do
      before :each do
        post :record_sep, qle_id: @qle.id, qle_date: Date.today
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id)}))
      end
    end

    context 'when its change of plan' do

      before :each do
        allow(@family).to receive(:enrolled_hbx_enrollments).and_return([ double ])
        post :record_sep, qle_id: @qle.id, qle_date: Date.today
      end

      it "should redirect with change_plan parameter" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id), change_plan: 'change_plan'}))
      end
    end
  end
end
