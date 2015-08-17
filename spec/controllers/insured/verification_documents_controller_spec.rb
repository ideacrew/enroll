require 'rails_helper'

RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:person) {FactoryGirl.create(:person)}
  let(:consumer_role) {FactoryGirl.creat(:consumer_role)}
  let(:consumer_wrapper) {Forms::ConsumerRole.new(consumer_role)}


  context "POST upload" do

    context "AWS returns nil" do
      it "redirects" do
        post :upload
        expect(response).to have_http_status(:redirect)
      end
    end

    context "save success"

  end
end
