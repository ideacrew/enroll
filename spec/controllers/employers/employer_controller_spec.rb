require 'rails_helper'

RSpec.describe Employers::EmployerController, :type => :controller do

  describe "GET new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET my_account" do
    it "returns http success" do
      get :my_account
      expect(response).to have_http_status(:success)
    end
  end

end
