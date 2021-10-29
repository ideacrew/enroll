require 'rails_helper'

include Dry::Monads[:result]

RSpec.describe Users::RegistrationsController, dbclean: :after_each do

  context "create" do
    let(:curam_user){ double("CuramUser") }
    let(:email){ "test@example.com" }
    let(:password){ "aA1!aA1!aA1!"}

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    context "without keycloak integration" do
      before do
        allow(EnrollRegistry).to receive(:[]).with(:identity_management_config).and_return(double(settings: double(item: '')))
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_call_original
        allow(EnrollRegistry).to receive(:[]).with(:saml_info_keys).and_call_original
      end

      context "when the email is in the black list" do
        before(:each) do
          allow(CuramUser).to receive(:match_unique_login).with(email).and_return([curam_user])
        end

        it "should redirect to saml recovery page if user matches" do
          post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
          expect(response).to be_success
          expect(flash[:alert]).to eq "An account with this username ( #{email} ) already exists. <a href=\"#{SamlInformation.account_recovery_url}\">Click here</a> if you've forgotten your password."
        end
      end

      context "when the email is not the black list" do

        before(:each) do
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
        end

        it "should re-render the page" do
          post :create, params: { user: { oim_id: email, password: password, password_confirmation: password } }
          expect(response).to be_success
          expect(response).not_to redirect_to(root_path)
        end
      end
    end

    context "with keycloak integration" do
      let(:user) { FactoryBot.create(:user, email: email, oim_id: email) }
      let(:operation) { double(Operations::Users::Create, call: Success(user: user)) }

      before do
        allow(Operations::Users::Create).to receive(:new).and_return(operation)
        allow(EnrollRegistry).to receive(:[]).with(:identity_management_config).and_return(double(settings: double(item: :keycloak)))
      end

      it 'calls Operations::Users::Create with account: params' do
        post :create, params: {
          user: {
            oim_id: "test@example.com",
            password: password,
            password_confirmation: password
          }
        }

        expect(operation).to have_received(:call).with(account: {
          email: email,
          password: password
        })
      end

      context "with a dupe user" do
        let(:user) { FactoryBot.build(:user, email: email, oim_id: email) }
        let(:operation) { double(Operations::Users::Create, call: Failure(user: user)) }

        it 're-renders the sign up form' do
          post :create, params: {
            user: {
              oim_id: "test@example.com",
              password: password,
              password_confirmation: password
            }
          }
          expect(response).to be_a_redirect
        end
      end
    end
  end
end
