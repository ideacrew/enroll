require 'rails_helper'

RSpec.describe Employers::FamilyController do
  let(:employer_profile_id) { "abecreded" }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:family) {FactoryGirl.create(:employer_census_family)}
  let(:new_family) {FactoryGirl.build(:employer_census_family)}

  describe "GET new" do
    let(:user) { double("user")}

    it "should render the new template" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("2015")
      sign_in(user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
      expect(assigns(:family).class).to eq EmployerCensus::EmployeeFamily
    end

    it "should redirect with no plan_years" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("")
      sign_in(user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to be_redirect
      expect(flash[:notice]).to eq "Please create a plan year before you create your first census family."
    end
  end

  describe "POST create" do
    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    end

    it "should be redirect when valid" do
      allow(employer_profile).to receive(:save).and_return(true)
      post :create, :employer_profile_id => employer_profile_id, employer_census_employee_family: {}
      expect(response).to be_redirect
    end

    it "should be render new template when invalid" do
      allow(employer_profile).to receive(:save).and_return(false)
      post :create, :employer_profile_id => employer_profile_id, employer_census_employee_family: {}
      expect(response).to render_template("new")
    end
  end

  describe "GET edit" do
    it "should be render edit template" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      post :edit, :id => family.id, :employer_profile_id => employer_profile_id, employer_census_employee_family: {}
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update" do
    before do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      allow(controller).to receive(:census_family_params).and_return({})
    end

    it "should be redirect when valid" do
      allow(family).to receive(:update_attributes).and_return(true)
      post :update, :id => family.id, :employer_profile_id => employer_profile_id, employer_census_employee_family: {}
      expect(response).to be_redirect
    end

    it "should be render edit template when invalid" do
      allow(family).to receive(:update_attributes).and_return(false)
      post :update, :id => family.id, :employer_profile_id => employer_profile_id, employer_census_employee_family: {}
      expect(response).to render_template("edit")
    end
  end

  describe "GET show" do
    it "should be render show template" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      get :show, :id => family.id, :employer_profile_id => employer_profile_id
      expect(response).to render_template("show")
    end
  end

  describe "GET delink" do
    it "should be redirect" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      get :delink, :family_id => family.id, :employer_profile_id => employer_profile_id
      expect(response).to be_redirect
    end
  end

  describe "GET terminate" do
    it "should be redirect" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      get :terminate, :family_id => family.id, :employer_profile_id => employer_profile_id
      expect(flash[:notice]).to eq "Successfully terminated family."
      expect(response).to be_redirect
    end
  end

  describe "GET rehire" do
    it "should be error without rehiring_date" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
      xhr :get, :rehire, :family_id => family.id, :employer_profile_id => employer_profile_id, :format => :js
      expect(response).to have_http_status(:success)
      expect(flash[:error]).to eq "Please enter rehiring date"
    end

    context "with rehiring_date" do
      it "should be error when has no new_family" do
        sign_in
        allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
        allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
        xhr :get, :rehire, :family_id => family.id, :employer_profile_id => employer_profile_id, rehiring_date: "05/01/2015", :format => :js
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to eq "Family is already active."
      end

      context "when has new_family" do
        before do
          sign_in
          allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
          allow(EmployerCensus::EmployeeFamily).to receive(:find).and_return(family)
          allow(family).to receive(:replicate_for_rehire).and_return(new_family)
        end

        it "save success" do
          allow(employer_profile).to receive(:save).and_return(true)
          xhr :get, :rehire, :family_id => family.id, :employer_profile_id => employer_profile_id, rehiring_date: "05/01/2015", :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:notice]).to eq "Successfully rehired family."
        end

        it "save failure" do
          allow(employer_profile).to receive(:save).and_return(false)
          xhr :get, :rehire, :family_id => family.id, :employer_profile_id => employer_profile_id, rehiring_date: "05/01/2015", :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:error]).to eq "Error during rehire."
        end
      end
    end
  end
end
