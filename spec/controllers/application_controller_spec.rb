require 'rails_helper'

RSpec.describe ApplicationController do
  controller(Employers::EmployerProfilesController) do
    def index
      render text: "Anonymous Index"
    end
  end

  context "when not signed in" do
    before do
  #    sign_in nil
      get :index
    end

    it "redirect to the sign in page" do
      expect(response).to redirect_to(new_user_registration_path)
    end

    it "should set portal in session" do
      expect(session[:portal]).to eq "http://test.host/employers/employer_profiles"
    end
  end

  context "when signed in with new user" do
    let(:user) { FactoryGirl.create("user") }

    it "should return the root url in dev environment" do
      expect( controller.send(:after_sign_out_path_for, user) ).to eq root_path
    end
  end

  context "when signed in" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
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
