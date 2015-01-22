require 'rails_helper'

RSpec.describe Employers::EmployerController, :type => :controller do

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = FactoryGirl.create(:user)
    sign_in user
  end

  describe "GET new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET my_account" do
    it "returns http success" do
      get :my_account, employer_id: 1
      expect(response).to have_http_status(:success)
    end
  end

end
