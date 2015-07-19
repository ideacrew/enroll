require 'rails_helper'

RSpec.describe Exchanges::InboxesController do
  context "GET show / DELETE destroy" do
    let(:user) { double("User") }
    let(:person) { double("Person") }
    let(:hbx_profile) { double("HbxProfile") }
    let(:message) { double("Message") }
    let(:inbox) { double("Inbox") }

    before do
      sign_in(user)
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
    end

    it "should render show" do
      get :show, id: "test"
      expect(response).to have_http_status(:success)
    end

    it "delete action" do
      xhr :delete, :destroy, id: 1
      expect(response).to have_http_status(:success)
    end
  end

end
