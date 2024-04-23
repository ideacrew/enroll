# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller, dbclean: :after_each do

  context "create" do
    let(:curam_user){ double("CuramUser") }
    let(:email){ "test@example.com" }
    let(:password){ "aA1!aA1!aA1!"}

    context "when the email is in the black list" do

      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        allow(CuramUser).to receive(:match_unique_login).with(email).and_return([curam_user])
      end

      it "should redirect to saml recovery page if user matches" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
        expect(response).to be_successful
        expect(flash[:alert]).to eq "An account with this username ( #{email} ) already exists. <a href=\"#{SamlInformation.account_recovery_url}\">Click here</a> if you've forgotten your password."
      end
    end

    context "when the email is not the black list" do

      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        allow(CuramUser).to receive(:match_unique_login).with("test@example.com").and_return([])
      end

      it "should not redirect to saml recovery page if user matches" do
        post :create, params: { user: { oim_id: "test@example.com", password: password, password_confirmation: password } }
        expect(response).not_to redirect_to(new_user_registration_path)
      end

    end

    context "account without person" do
      let(:email) { "devise@test.com" }
      let!(:user) { FactoryBot.create(:user, email: email, oim_id: email) }

      before do
        @request.env["devise.mapping"] = Devise.mappings[:user]
      end

      it "should complete sign up and redirect" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "account with person" do
      let(:email) { "devisepersoned@test.com"}
      let(:user) { FactoryBot.create(:user, email: email, person: person, oim_id: email) }
      let(:person) { FactoryBot.create(:person) }

      before do
        user.save!
        @request.env["devise.mapping"] = Devise.mappings[:user]
      end

      it "should re-render the page" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
        expect(response).to be_successful
        expect(response).not_to redirect_to(root_path)
      end
    end

    context "with weak password" do
      let(:email) { "test@test.com"}
      let(:user) { FactoryBot.create(:user, email: email, person: person, oim_id: email) }
      let(:person) { FactoryBot.create(:person) }

      before do
        user.save!
        @request.env["devise.mapping"] = Devise.mappings[:user]
        #allow(controller).to receive(:resource).and_return(nil)
      end

      it "should render the 'new' template" do
        post :create, params: { user: { oim_id: email, password: 'Password1$', password_confirmation: 'Password1$'} }
        expect(response).to be_successful
        expect(response).to render_template("new")
      end
    end

    context "with invalid captcha" do
      let(:email) { "devise9998@test.com" }

      before do
        FactoryBot.create(:user, email: email, oim_id: email)
        @request.env["devise.mapping"] = Devise.mappings[:user]
        allow(controller).to receive(:verify_recaptcha_if_needed).and_return(false)
      end

      it "does not redirect" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }

        expect(response).not_to redirect_to(root_path)
      end
    end

    context "with valid params and valid/invalid format" do
      let(:email) { "devise12345@test.com" }
      let(:password) { 'Password12345!' }

      before do
        @request.env["devise.mapping"] = Devise.mappings[:user]
      end

      it "should complete sign up and redirect" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
        expect(response).to redirect_to(root_path)
      end

      it "should not be successful" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }, format: :js
        expect(response).to_not be_successful
        expect(response).not_to redirect_to(root_path)
      end

      it "should not be successful" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }, format: :json
        expect(response).to_not be_successful
      end

      it "should not be successful" do
        post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }, format: :xml
        expect(response).to_not be_successful
      end
    end
  end
end
