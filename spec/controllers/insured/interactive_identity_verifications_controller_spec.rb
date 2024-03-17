require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe Insured::InteractiveIdentityVerificationsController do

    describe "GET #new" do
      let(:mock_person) { double(agent?: false, policy_class: PersonPolicy) }
      let(:mock_family) { instance_double("Family") }
      let(:mock_transaction_id) { double }
      let(:mock_user) { double(:person => mock_person) }
      let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
      let(:mock_service_result) { instance_double("::IdentityVerification::InteractiveVerificationResponse", :failed? => service_failed, :to_model => mock_session, :transaction_id => mock_transaction_id) }
      let(:mock_session) { double }
      let(:mock_template_result) { double }
      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }

      before :each do
        allow(PersonPolicy).to receive(:new).with(mock_user, mock_person).and_return(mock_policy)
        sign_in(mock_user)
        allow(mock_person).to receive(:primary_family).and_return(mock_family)
        allow(mock_person.primary_family).to receive(:most_recent_and_draft_financial_assistance_application).and_return nil
        allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
        allow(controller).to receive(:render_to_string).with(
          "events/identity_verification/interactive_session_start",
          {
            :formats => ["xml"],
            :locals => { :individual => mock_person }
          }
        ).and_return(mock_template_result)
      end

      describe "when the initial request results in failure" do
        let(:service_failed) { true }

        it "should render the 'please call' message" do
          allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(mock_service_result)
          get :new
          expect(assigns[:verification_response]).to eq mock_service_result
          expect(response).to redirect_to(failed_validation_insured_interactive_identity_verifications_path(:step => 'start', :verification_transaction_id => mock_transaction_id))
        end
      end

      describe "when the initial request results in service unavailable" do
        it "should render the 'try back later' message" do
          allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(nil)
          get :new
          expect(response).to redirect_to(service_unavailable_insured_interactive_identity_verifications_path)
        end
      end


      describe "when the initial request returns questions" do
        let(:service_failed) { false }
        it "should render the question response form" do
          expect(controller).to receive(:render_to_string).with(
            "events/identity_verification/interactive_session_start",
            {
              :formats => ["xml"],
              :locals => { :individual => mock_person }
            }
          ).and_return(mock_template_result)
          allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(mock_service_result)
          get :new
          expect(assigns[:interactive_verification]).to eq mock_session
          expect(response).to render_template("new")
        end
      end
    end

    describe "POST #create" do
      let(:mock_person_user) { instance_double("User") }
      let(:mock_consumer_role) { instance_double("ConsumerRole", id: "test") }
      let(:mock_person) { double(:consumer_role => mock_consumer_role, :user => mock_person_user, agent?: false, policy_class: PersonPolicy) }
      let(:mock_family) { instance_double("Family") }
      let(:email) { double(:address => 'test@test.com') }
      let(:mock_user) { double(:person => mock_person) }
      let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
      let(:mock_response_description_text) { double }
      let(:mock_transaction_id) { double }
      let(:mock_service_result) { double(:successful? => service_succeeded, :response_text => mock_response_description_text, :transaction_id => mock_transaction_id) }
      let(:mock_session) { instance_double("::IdentityVerification::InteractiveVerification", :valid? => valid_verification) }
      let(:mock_template_result) { double }
      let(:expected_params) { verification_params }
      let(:mock_today) { double }
      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }

      before :each do
        allow(PersonPolicy).to receive(:new).with(mock_user, mock_person).and_return(mock_policy)
        sign_in(mock_user)
        allow(mock_person).to receive(:emails).and_return([email])
        allow(mock_person).to receive(:first_name).and_return("john")
        allow(mock_person).to receive(:primary_family).and_return(mock_family)
        allow(mock_person.primary_family).to receive(:most_recent_and_draft_financial_assistance_application).and_return nil
        allow(::IdentityVerification::InteractiveVerification).to receive(:new).with(expected_params).and_return(mock_session)
      end

      describe "with an invalid interactive_verification" do
        let(:verification_params) { { :session_id => "sure why not", :transaction_id => "1234" } }
        let(:valid_verification) { false }
        it "should render new" do
          post :create, params: { "interactive_verification" => verification_params }
          expect(assigns[:interactive_verification]).to eq mock_session
          expect(response).to render_template("new")
        end
      end

      describe "with valid interactive_verification" do
        let(:verification_params) do
          {
            :session_id => "abcde", :transaction_id => "abcdef",
            :questions_attributes => {
              "0" => {
                "question_id" => "1",
                "question_text" => "some text here",
                "response_id" => "234566",
                "responses_attributes" => {
                  "0" => {
                    "response_text" => "r_text",
                    "response_id" => "r_id"
                  }
                }
              }
            }
          }
        end
        let(:valid_verification) { true }

        before :each do
          allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
          allow(controller).to receive(:render_to_string).with(
            "events/identity_verification/interactive_questions_response",
            {
              :formats => ["xml"],
              :locals => { :session => mock_session }
            }
          ).and_return(mock_template_result)
          allow(mock_service).to receive(:respond_to_questions).with(mock_template_result).and_return(mock_service_result)
        end

        describe "when the service is unreachable" do
          let(:mock_service_result) { nil }

          it "should render the 'try back later' message" do
            post :create, params: { "interactive_verification" => verification_params }
            expect(response).to redirect_to(service_unavailable_insured_interactive_identity_verifications_path)
          end
        end

        describe "when verification is not successful" do
          let(:service_succeeded) { false }
          it "should render the 'please call' message" do
            post :create, params: { "interactive_verification" => verification_params }
            expect(assigns[:verification_response]).to eq mock_service_result
            expect(response).to redirect_to(failed_validation_insured_interactive_identity_verifications_path(:step => 'questions', :verification_transaction_id => mock_transaction_id))
          end
        end

        describe "when verification is successful" do
          let(:service_succeeded) { true }
          it "should redirect the user" do
            allow(TimeKeeper).to receive(:date_of_record).and_return(mock_today)
            allow(mock_person.consumer_role).to receive(:admin_bookmark_url).and_return false
            expect(mock_person_user).to receive(:identity_final_decision_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
            expect(mock_person_user).to receive(:identity_response_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
            expect(mock_person_user).to receive(:identity_response_description_text=).with(mock_response_description_text)
            expect(mock_person_user).to receive(:identity_final_decision_transaction_id=).with(mock_transaction_id)
            expect(mock_person_user).to receive(:identity_verified_date=).with(mock_today)
            expect(mock_person_user).to receive(:save!)
            expect(mock_person.consumer_role).to receive(:move_identity_documents_to_verified).and_return true
            post :create, params: { "interactive_verification" => verification_params }
            expect(response).to be_redirect
          end
        end
      end
    end

    describe "POST #update" do
      let(:mock_person_user) { instance_double("User") }
      let(:mock_consumer_role) { instance_double("ConsumerRole", id: "test") }
      let(:mock_person) { double(:consumer_role => mock_consumer_role, :user => mock_person_user, agent?: false, policy_class: PersonPolicy) }
      let(:mock_family) { instance_double("Family") }
      let(:email) { double(:address => 'test@test.com') }
      let(:mock_user) { double(:person => mock_person) }
      let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
      let(:mock_response_description_text) { double }
      let(:mock_transaction_id) { double }
      let(:mock_service_result) { double(:successful? => service_succeeded, :response_text => mock_response_description_text, :transaction_id => mock_transaction_id) }
      let(:mock_template_result) { double }
      let(:expected_params) { verification_params }
      let(:mock_today) { double }
      let(:transaction_id) { "aadsdlkmcee" }

      let(:service_succeeded) { false }

      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }

      before :each do
        allow(PersonPolicy).to receive(:new).with(mock_user, mock_person).and_return(mock_policy)
        sign_in(mock_user)
        allow(mock_person).to receive(:emails).and_return([email])
        allow(mock_person).to receive(:first_name).and_return("john")
        allow(mock_person).to receive(:primary_family).and_return(mock_family)
        allow(mock_person.primary_family).to receive(:most_recent_and_draft_financial_assistance_application).and_return nil
        allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
        allow(controller).to receive(:render_to_string).with(
          "events/identity_verification/interactive_verification_override",
          {
            :formats => ["xml"],
            :locals => { :transaction_id => transaction_id }
          }
        ).and_return(mock_template_result)
        allow(mock_service).to receive(:check_override).with(mock_template_result).and_return(mock_service_result)
      end

      describe "when the service is unreachable" do
        let(:mock_service_result) { nil }

        it "should render the 'try back later' message" do
          post :update, params: { "id" => transaction_id }
          expect(response).to redirect_to(service_unavailable_insured_interactive_identity_verifications_path)
        end
      end

      describe "when verification is not successful" do
        let(:service_succeeded) { false }
        it "should render the 'please call' message" do
          post :update, params: { "id" => transaction_id }
          expect(assigns[:verification_response]).to eq mock_service_result
          expect(response).to redirect_to(failed_validation_insured_interactive_identity_verifications_path(:verification_transaction_id => mock_transaction_id))
        end
      end

      describe "when verification is successful" do
        let(:service_succeeded) { true }
        it "should redirect the user" do
          allow(TimeKeeper).to receive(:date_of_record).and_return(mock_today)
          allow(mock_person.consumer_role).to receive(:admin_bookmark_url).and_return false
          expect(mock_person_user).to receive(:identity_final_decision_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
          expect(mock_person_user).to receive(:identity_response_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
          expect(mock_person_user).to receive(:identity_response_description_text=).with(mock_response_description_text)
          expect(mock_person_user).to receive(:identity_final_decision_transaction_id=).with(mock_transaction_id)
          expect(mock_person_user).to receive(:identity_verified_date=).with(mock_today)
          expect(mock_person_user).to receive(:save!)
          expect(mock_person.consumer_role).to receive(:move_identity_documents_to_verified).and_return true
          post :update, params: { "id" => transaction_id }
          expect(response).to be_redirect
        end

        context "with admin_bookmark_url set on consumer role" do
          before do
            allow(mock_person.consumer_role).to receive(:admin_bookmark_url).and_return true
          end

          context 'consumer has most recent existing application in draft state' do
            let(:mock_application) { instance_double("FinancialAssistance::Application", id: "12345") }
            let(:mock_family) { instance_double("Family") }
            before do
              allow(mock_person).to receive(:primary_family).and_return(mock_family)
              allow(mock_person.primary_family).to receive(:most_recent_and_draft_financial_assistance_application).and_return mock_application
            end

            context 'with draft_application_after_ridp feature enabled' do
              before do
                allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
                allow(EnrollRegistry).to receive(:feature_enabled?).with(:draft_application_after_ridp).and_return(true)
              end

              it 'should redirect to draft application edit page' do
                edit_application_path = FinancialAssistance::Engine.routes.url_helpers.edit_application_path(mock_application.id).split('/.').last
                allow(TimeKeeper).to receive(:date_of_record).and_return(mock_today)
                expect(mock_person_user).to receive(:identity_final_decision_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
                expect(mock_person_user).to receive(:identity_response_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
                expect(mock_person_user).to receive(:identity_response_description_text=).with(mock_response_description_text)
                expect(mock_person_user).to receive(:identity_final_decision_transaction_id=).with(mock_transaction_id)
                expect(mock_person_user).to receive(:identity_verified_date=).with(mock_today)
                expect(mock_person_user).to receive(:save!)
                expect(mock_person.consumer_role).to receive(:move_identity_documents_to_verified).and_return true
                post :update, params: { "id" => transaction_id }
                expect(response).to have_http_status(:redirect)
                expect(response).to redirect_to(edit_application_path)
              end
            end
          end
        end
      end
    end

    describe "GET #service_unavailable" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:mock_user) { FactoryBot.create(:user, :person => person) }
      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }
      before :each do
        allow(PersonPolicy).to receive(:new).with(mock_user, person).and_return(mock_policy)
        allow(mock_user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(mock_user)
      end

      it "should render new template" do
        get :service_unavailable
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:service_unavailable)
      end
    end

    describe "GET #failed_validation" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:mock_transaction_id) { double }
      let(:mock_user) { FactoryBot.create(:user, :person => person) }
      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }
      before :each do
        allow(PersonPolicy).to receive(:new).with(mock_user, person).and_return(mock_policy)
        allow(mock_user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(mock_user)
      end

      it "should render new template" do
        get :failed_validation, params: { :step => 'start', :verification_transaction_id => mock_transaction_id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:failed_validation)
      end
    end

    describe '.failed_validation' do
      let(:user){ FactoryBot.create(:user, :consumer, person: person) }
      let(:person){ FactoryBot.create(:person, :with_consumer_role) }
      let(:mock_policy) { instance_double(PersonPolicy, :complete_ridp? => true) }

      context "GET failed_validation", dbclean: :after_each do
        before(:each) do
          allow(PersonPolicy).to receive(:new).with(user, person).and_return(mock_policy)
          sign_in user
          allow(user).to receive(:person).and_return(person)
        end

        it "should render template" do
          get :failed_validation, params: {}

          expect(response).to have_http_status(:success)
          expect(response).to render_template("failed_validation")
        end
      end
    end
  end

  describe Insured::InteractiveIdentityVerificationsController, "given an unauthorized user" do
    let(:mock_user) do
      instance_double(
        User,
        :has_hbx_staff_role? => false,
        :person => mock_person
      )
    end
    let(:mock_person) do
      double(
        policy_class: PersonPolicy
      )
    end
    let(:mock_policy) do
      instance_double(
        PersonPolicy,
        :complete_ridp? => false
      )
    end

    before :each do
      allow(PersonPolicy).to receive(:new).with(mock_user, mock_person).and_return(mock_policy)
      sign_in(mock_user)
    end

    it "denies access to GET #new" do
      get :new
      expect(response.status).to eq 302
    end

    it "denies access to POST #create" do
      post :create, params: {}
      expect(response.status).to eq 302
    end

    it "denies access to POST #update" do
      post :update, params: { :id => "some random ID" }
      expect(response.status).to eq 302
    end

    it "denies access to GET #service_unavailable" do
      get :service_unavailable
      expect(response.status).to eq 302
    end

    it "denies access to GET #failed_validation" do
      get :failed_validation
      expect(response.status).to eq 302
    end
  end
end
