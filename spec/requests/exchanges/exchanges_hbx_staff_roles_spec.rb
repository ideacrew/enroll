require 'rails_helper'

RSpec.describe "Exchanges::HbxStaffRoles", :type => :request do
  describe "GET /exchanges_hbx_staff_roles" do
    it "works! (now write some real specs)" do
      get exchanges_hbx_staff_roles_path
      expect(response).to have_http_status(200)
    end
  end
end
