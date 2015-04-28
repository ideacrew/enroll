require 'rails_helper'
require 'factories/enrollment_factory'

RSpec.describe Consumer::EmployeeDependentsController do
  describe "GET index" do
    let(:user) { instance_double("User", :primary_family => family, :person => person) }
    let(:family) { double }
    let(:person) { double }

    before(:each) do
      sign_in(user)
      get :index
    end

    it "renders the 'index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end

    it "assigns the person" do
      expect(assigns(:person)).to eq person
    end

    it "assigns the family" do
      expect(assigns(:family)).to eq family
    end
  end

  describe "GET new" do
    let(:user) { instance_double("User", :person => person) }
    let(:family) { double }
    let(:person) { double }
    let(:family_id) { "addbedddedtotallyafamiyid" }
    let(:dependent) { double }

    before(:each) do
      sign_in(user)
      allow(Forms::EmployeeDependent).to receive(:new).with({:family_id => family_id}).and_return(dependent)
      get :new, :family_id => family_id
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

    it "assigns the family" do
      expect(assigns(:dependent)).to eq dependent
    end
  end
end
