require 'rails_helper'

RSpec.describe Hbx::HbxController, :type => :controller do
  let(:user) { double("user")}

  describe "GET welcome" do
    context "has hbx role" do
      it "should render the welcome template" do
        allow(user).to receive(:has_hbx_staff_role?).and_return(true)
        sign_in(user)
        get :welcome
        expect(response).to have_http_status(:success)
      end
    end

    context "has no hbx role" do
      it "should redirect back to root" do
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        get :welcome
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
