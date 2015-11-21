require 'rails_helper'

RSpec.describe Users::RegistrationsController do

  context "create" do

    let(:curam_user){ double("CuramUser") }

    context "when the email is in the black list" do

      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        allow(CuramUser).to receive(:match_email).with("test@example.com").and_return([curam_user])
      end

      it "should redirect to saml recovery page if user matches" do
        post :create, { user: { email: "test@example.com", password: "password", password_confirmation: "password" } }
        expect(response).to redirect_to(SamlInformation.account_recovery_url)
      end

    end

    context "when the email is not the black list" do

      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        allow(CuramUser).to receive(:match_email).with("test@example.com").and_return([])
      end

      it "should not redirect to saml recovery page if user matches" do
        post :create, { user: { email: "test@example.com", password: "password", password_confirmation: "password" } }
        expect(response).not_to redirect_to(SamlInformation.account_recovery_url)
      end

    end

  end

end