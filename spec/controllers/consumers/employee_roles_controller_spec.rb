require 'rails_helper'

RSpec.describe Consumer::EmployeeRolesController, :type => :controller do
  describe "POST match" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:mock_person) { instance_double("Forms::ConsumerIdentity", :valid? => validation_result) }

    before(:each) do
      sign_in 
      allow(Forms::ConsumerIdentity).to receive(:new).with(person_parameters).and_return(mock_person)
      post :match, :person => person_parameters
    end
    context "given valid parameters" do
      let(:validation_result) { true }

      it "renders the 'match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns[:person]).to eq mock_person
      end
    end

    context "given invalid parameters" do
      let(:validation_result) { false }
      it "renders the 'match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:person]).to eq mock_person
      end
    end
  end

  describe "GET search" do

    before(:each) do
      sign_in
      get :search
    end

    it "renders the 'search' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns[:person]).to be_a(Forms::ConsumerIdentity)
    end
  end

  describe "GET welcome" do

    before(:each) do
      sign_in
      get :welcome
    end

    it "renders the 'welcome' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("welcome")
    end
  end

  describe "GET new" do
    login_user

    before(:each) do
      get :new
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(assigns(:person)).to be_a_new(Person)
    end
  end
end
