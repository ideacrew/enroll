require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::ProfilesController, type: :controller do

    describe "GET #employers" do
      it "returns http success" do
        get :employers
        expect(response).to have_http_status(:success)
      end
    end

  end
end
