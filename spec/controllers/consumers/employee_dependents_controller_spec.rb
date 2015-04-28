require 'rails_helper'
require 'factories/enrollment_factory'

RSpec.describe Consumer::EmployeeDependentsController do
  describe "GET index" do
    let(:user) { instance_double("User", :primary_family => family) }
    let(:family) { double("family") }

    before(:each) do
      sign_in(user)
      get :index
    end

    it "renders the 'index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end

    it "sets the family" do
      expect(assigns(:family)).to eq family
    end
  end
end
