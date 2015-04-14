require 'rails_helper'

RSpec.describe ApplicationController do
  controller(Employers::EmployerProfilesController) do
    def index
      render text: "Anonymous Index"
    end
  end

  context "when not signed in" do
    before do
      sign_in nil
      get :index
    end

    it "redirect to the sign in page" do
      expect(response).to redirect_to(new_user_session_url)
    end

    it "should set portal in session" do
      expect(session[:portal]).to eq "http://test.host/employers/employer_profiles"
    end
  end

  context "when signed in" do
    before do
      sign_in
      get :index
    end

    it "returns http success" do
      expect(response).not_to redirect_to(new_user_session_url)
    end

    it "doesn't set portal in session" do
      expect(session[:portal]).not_to be
    end
  end
end
