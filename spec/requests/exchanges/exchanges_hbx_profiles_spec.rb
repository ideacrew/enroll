require 'rails_helper'

RSpec.describe "HbxProfiles", :type => :request do
  describe "GET /hbx_profiles" do
    it "works! (now write some real specs)" do
      get hbx_profiles_path
      expect(response).to have_http_status(200)
    end
  end
end
