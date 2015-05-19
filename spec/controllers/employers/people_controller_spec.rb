require 'rails_helper'

RSpec.describe Employers::PeopleController do
  describe "GET search" do
    let(:user) { double("user") }
    let(:person) { double("person")}

    it "renders the 'search' template" do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :search
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns(:person).class).to eq (Forms::EmployeeCandidate)
    end
  end

  describe "POST match" do
    let(:user) { double("user") }
    let(:phones) {double(:select => double("select")) }
    let(:addresses) {double(:select => double("select")) }
    let(:emails) {double(:select => double("select")) }
    let(:person) { double(:phones => phones, :addresses => addresses, :emails => emails)}
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:more_params){{:create_person => "create", person: person_parameters}}
    let(:found_person) { [] }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result) }
    let(:save_result) {true}

    before(:each) do
      allow(user).to receive(:instantiate_person).and_return(person)
      allow(person).to receive(:attributes=).and_return(person_parameters)
      allow(person).to receive(:save).and_return(save_result)
      sign_in(user)
      allow(Forms::EmployeeCandidate).to receive(:new).with(person_parameters).and_return(mock_employee_candidate)
      allow(mock_employee_candidate).to receive(:match_person).and_return(found_person)
      post :match, more_params
    end

    context "it should create person when create person button is clicked" do
      let(:validation_result) { true }

      it "shoudl call create method" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end

  describe "POST match" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:found_person) { [] }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result) }

    before(:each) do
      sign_in
      allow(Forms::EmployeeCandidate).to receive(:new).with(person_parameters).and_return(mock_employee_candidate)
      allow(mock_employee_candidate).to receive(:match_person).and_return(found_person)
      post :match, :person => person_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { false }

      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
      end
    end

    context "given valid parameters render 'no_match' template" do
      let(:validation_result) { true }

      it "renders the 'no_match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("no_match")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
        expect(assigns(:person).class).to eq Person
      end

    end

    context "given valid parameters render 'match' template" do
      let(:validation_result) { true }
      let(:found_person) { FactoryGirl.create(:person) }

      it "renders the 'match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
      end
    end
  end

  describe "POST update" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING", :last_name => "SOME"} }
    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user) }

    before(:each) do
      sign_in(user)
      allow(Person).to receive(:find).with(person.id).and_return(person)
      allow(person).to receive(:update_attributes).and_return(save_result)
      allow(controller).to receive(:sanitize_person_params).and_return(nil)
      allow(controller).to receive(:make_new_person_params).with(person).and_return(nil)
      put :update, :person => person_parameters, :id => person.id
    end

    context "given valid person parameters" do
      let(:save_result) { true }

      it "should render 'employer_form'" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("employer_form")
      end
    end
  end
end
