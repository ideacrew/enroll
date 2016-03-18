require 'rails_helper'

RSpec.describe GeneralAgencies::InboxesController do
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  describe "Get new" do
    before do
      sign_in user
      xhr :get, :new, :id => general_agency_profile.id, profile_id: hbx_profile.id, to: "test", format: :js
    end

    it "render new template" do
      expect(response).to render_template("new")
      expect(response).to have_http_status(:success)
    end
  end
end
