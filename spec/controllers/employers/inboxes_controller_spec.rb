require 'rails_helper'

RSpec.describe Employers::InboxesController, :type => :controller do
  describe "Get new" do
    let(:inbox_provider){double(:inbox_provider)}
    before do 
      allow(EmployerProfile).to receive(:find).and_return(inbox_provider)
    end

    it "render new template" do
      get :new
      expect(response).to have_http_status(:redirect)
      #expect(response).to render_template("new")
    end
  end
end
