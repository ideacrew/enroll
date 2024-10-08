require 'rails_helper'

RSpec.describe SamlController do


  describe "POST login", db_clean: :after_each do
    let(:user) { FactoryBot.create(:user, last_portal_visited: family_account_path)}

    invalid_xml = File.read("spec/saml/invalid_saml_response.xml")

    context "user with admin role" do
      let(:admin_user) { FactoryBot.create(:user, last_portal_visited: family_account_path, roles: ["hbx_staff"])}
      let(:admin_person) { FactoryBot.create(:person, :user => admin_user)}
      let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: admin_person) }
      sample_xml = File.read("spec/saml/invalid_saml_response.xml")
      let(:name_id) { admin_user.oim_id }
      let(:valid_saml_response) { double(is_valid?: true, :"settings=" => true, attributes: attributes_double, name_id: name_id, sessionindex: "12345")}
      let(:attributes_double) { { 'mail' => admin_user.email} }

      before :each do
        allow(valid_saml_response).to receive(:is_a?).with(OneLogin::RubySaml::Response).and_return(true)
        allow(OneLogin::RubySaml::Response).to receive(:new).with(sample_xml, :allowed_clock_drift => 5.seconds).and_return(valid_saml_response)
      end

      context "with admin account autolock feature enabled", dbclean: :after_each do
        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:admin_account_autolock).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:notify_address_changed).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:financial_assistance).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_publish_updated_families).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:sensor_tobacco_carrier_usage).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:saml_single_logout).and_return(false)
          hbx_staff_role
        end

        context "with last activity at greater than 60 days" do
          before do
            admin_user.set(last_activity_at: 61.days.ago)
          end

          it "redirects to account expired path" do
            post :login, params: {SAMLResponse: sample_xml}
            expect(response).to redirect_to(account_expired_saml_index_path)
          end
        end

        context "with last activity at less than 60 days" do

          it "redirects to last portal visited" do
            post :login, params: {SAMLResponse: sample_xml}
            expect(response).to redirect_to(admin_user.last_portal_visited)
          end
        end
      end

      context "with admin account autolock feature disabled", dbclean: :after_each do

        it "redirects to last portal visited" do
          post :login, params: {SAMLResponse: sample_xml}
          expect(response).to redirect_to(admin_user.last_portal_visited)
        end

        it "shows success message" do
          post :login, params: {SAMLResponse: sample_xml}
          expect(flash[:notice]).to eq "Signed in Successfully."
        end
      end
    end

    context "with invalid saml response" do

      it "should render a 403" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to match(/ERROR: SAMLResponse assertion errors/)
          expect(arg2).to eq(:severity => 'error')
        end

        post :login, params: {SAMLResponse: invalid_xml}
        expect(response).to have_http_status(403)
      end
    end

    context "with valid saml response" do
      sample_xml = File.read("spec/saml/invalid_saml_response.xml")
      let(:name_id) { user.oim_id }
      let(:valid_saml_response) { double(is_valid?: true, :"settings=" => true, attributes: attributes_double, name_id: name_id, sessionindex: "12345")}
      let(:attributes_double) { { 'mail' => user.email} }

      before do
        allow(valid_saml_response).to receive(:is_a?).with(OneLogin::RubySaml::Response).and_return(true)
        allow(OneLogin::RubySaml::Response).to receive(:new).with(sample_xml, :allowed_clock_drift => 5.seconds).and_return( valid_saml_response )
      end

      describe "with an existing user", db_clean: :after_each do
        let(:person) {FactoryBot.create(:person, user: user, ssn: "654333333")}

        it "should redirect back to their last portal" do
          expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
          post :login, params: {SAMLResponse: sample_xml}
          expect(response).to redirect_to(user.last_portal_visited)
          expect(flash[:notice]).to eq "Signed in Successfully."
          expect(User.where(email: user.email).first.oim_id).to eq name_id
          expect(User.where(email: user.email).first.idp_verified).to be_truthy
        end

        context "with relay state" do
          let(:relay_state_url) { "/employers/employer_profiles/new" }

          it "should redirect back to their the relay state" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, params: {SAMLResponse: sample_xml, RelayState: relay_state_url}
            expect(response).to redirect_to(relay_state_url)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: user.email).first.oim_id).to eq name_id
            expect(User.where(email: user.email).first.idp_verified).to be_truthy
          end
        end
      end

      context "With a new user with existing email" do
        sample_xml = File.read("spec/saml/invalid_saml_response.xml")
        let!(:user3) { FactoryBot.create(:user, last_portal_visited: family_account_path)}
        let!(:user4) { FactoryBot.create(:user, last_portal_visited: family_account_path)}
        let!(:person4) { FactoryBot.create :person, :with_family, :user => user4}
        let(:valid_saml_response) { double(is_valid?: true, name_id: 'Testing@test.com', :"settings=" => true, attributes: attributes_double, sessionindex: "12345") }
        let(:attributes_double) { { 'mail' => user4.email} }
        let(:relay_state_url) { "/employers/employer_profiles/new" }

        before do
          allow(OneLogin::RubySaml::Response).to receive(:new).with(sample_xml, :allowed_clock_drift => 5.seconds).and_return(valid_saml_response)
        end

        it "should redirect to login page with error flash" do
          post :login, params: {SAMLResponse: sample_xml, RelayState: relay_state_url}
          expect(response).to redirect_to(SamlInformation.iam_login_url)
          expect(flash[:error]).to eq "Invalid User Details."
        end
      end

      describe "with a new user", dbclean: :after_each do
        let(:name_id) { attributes_double['mail'] }
        let(:attributes_double) { { 'mail' => "new@user.com"} }

        it "should claim the invitation" do
          expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
          post :login, params: {SAMLResponse: sample_xml}
          expect(response).to redirect_to(search_insured_consumer_role_index_path)
          expect(flash[:notice]).to eq "Signed in Successfully."
          expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
          expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
        end

        context "who has a headless user with same email but different username" do
          let!(:email_matched_user) { FactoryBot.create(:user, email: attributes_double['mail'])}

          it "should claim the invitation" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, params: {:SAMLResponse => sample_xml}
            expect(response).to redirect_to(search_insured_consumer_role_index_path)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
            expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
          end
        end

        context "with no email attribute passed" do
          let(:name_id) { "someuser"}
          let(:attributes_double) { { } }

          it "should claim the invitation" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, params: {SAMLResponse: sample_xml}
            expect(response).to redirect_to(search_insured_consumer_role_index_path)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(oim_id: name_id).first.oim_id).to eq name_id
            expect(User.where(oim_id: name_id).first.idp_verified).to be_truthy
          end

          context "with a user that already has an empty e-mail" do
            let(:name_id) { "someotheruser"}
            let(:attributes_double) { { } }

            it "should claim the invitation" do
              expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
              post :login, params: {SAMLResponse: sample_xml}
              expect(response).to redirect_to(search_insured_consumer_role_index_path)
              expect(flash[:notice]).to eq "Signed in Successfully."
              expect(User.where(oim_id: name_id).first.oim_id).to eq name_id
              expect(User.where(oim_id: name_id).first.idp_verified).to be_truthy
            end
          end
        end

        context "with relay state" do
          let(:attributes_double) { { 'mail' => "another_new@user.com"} }
          let(:relay_state_url) { "/insured/employee/search" }

          it "should redirect back to the relay state url" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, params: {SAMLResponse: sample_xml, RelayState: relay_state_url}
            expect(response).to redirect_to(relay_state_url)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
            expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
          end
        end
      end

      context "with no name id attribute" do
         let(:name_id) { nil }

        it "should render a 403 and log the error as critical" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to match(/ERROR: SAMLResponse has missing required mail attribute/)
            expect(arg2).to eq(:severity => 'critical')
          end

          post :login, params: {SAMLResponse: sample_xml}
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe "GET account_expired", db_clean: :after_each do
    it "shows error message" do
      get :account_expired
      expect(flash[:error]).to eq l10n('devise.failure.expired')
    end
  end

  describe "GET navigate_to_assistance", db_clean: :after_each do
    before :each do
      allow(EnrollRegistry[:medicaid_tax_credits_link].feature).to receive(:is_enabled).and_return(true)
    end

    context "logged on user" do
      let(:user) { FactoryBot.create(:user, last_portal_visited: family_account_path, oim_id: 'some_curam_id')}

      it "should redirect user to curam URL" do
        sign_in user
        allow(::IdpAccountManager).to receive(:update_navigation_flag).with(user.oim_id, user.email, ::IdpAccountManager::CURAM_NAVIGATION_FLAG)
        get :navigate_to_assistance
        expect(response).to redirect_to(URI.parse(SamlInformation.curam_landing_page_url).to_s)
      end
    end

    context "user not logged on" do
      it "should redirect user to login URL" do
        allow(controller).to receive(:current_user).and_return(nil)
        get :navigate_to_assistance
        expect(response).to redirect_to(SamlInformation.iam_login_url)
      end
    end
  end

end
