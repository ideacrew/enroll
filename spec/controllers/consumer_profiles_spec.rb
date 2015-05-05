require "rails_helper"

describe ConsumerProfilesController do
  describe "GET home" do
    before(:each) do
      sign_in
      get :home
    end

    it "should be successful" do
      expect(response).to have_http_status(:success)
    end
  end
end
