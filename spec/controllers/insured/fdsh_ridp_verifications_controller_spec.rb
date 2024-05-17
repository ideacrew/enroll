#frozen_string_literal: true

require 'rails_helper'

describe Insured::FdshRidpVerificationsController do
  include Dry::Monads[:do, :result]

  describe 'find response' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:person1) { FactoryBot.create(:person, :with_family) }
    let(:person2) { FactoryBot.create(:person, :with_family) }
    let!(:primary_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: DateTime.now) }
    let!(:secondary_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: nil)}
    let!(:third_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person1.hbx_id, deleted_at: DateTime.now)}
    let!(:fourth_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person1.hbx_id, deleted_at: DateTime.now - 2.day)}
    let!(:fifth_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'secondary', primary_member_hbx_id: person.hbx_id, deleted_at: DateTime.now) }

    before do
      controller.instance_variable_set(:@person, person)
    end

    it 'finds a primary response' do
      expect(controller.send(:find_response, 'primary')).to eq(primary_event)
    end

    context "with nil deleted at dates" do

      it "should not include eligibility response models" do
        expect(controller.send(:find_response, 'primary').to_a.count).to eql(1)
      end
    end

    context "with no records" do
      before do
        controller.instance_variable_set(:@person, person2)
      end

      it "should return nil" do
        expect(controller.send(:find_response, 'primary')).to eql(nil)
      end
    end

    context "with multiple records with different primary hbx_id" do

      before do
        controller.instance_variable_set(:@person, person1)
      end

      it "should only return records related to one primary hbx_id" do
        expect(controller.send(:find_response, 'primary').to_a.count).to eql(1)
      end
    end

    context "with different event kinds" do

      it "should only return one event kind" do
        expect(controller.send(:find_response, 'secondary')).to eql(fifth_event)
      end
    end
  end

  describe '.failed_validation' do
    let(:user){ FactoryBot.create(:user, :consumer, person: person) }
    let(:person){ FactoryBot.create(:person, :with_consumer_role) }

    before(:each) do
      sign_in user
      allow(user).to receive(:person).and_return(person)
    end

    context "GET failed_validation", dbclean: :after_each do
      it "should render template" do
        allow_any_instance_of(ConsumerRole).to receive(:move_identity_documents_to_outstanding).and_return(true)
        get :failed_validation, params: {}

        expect(response).to have_http_status(:success)
        expect(response).to render_template("failed_validation")
      end

      it "should render template when correct person id is passed" do
        allow_any_instance_of(ConsumerRole).to receive(:move_identity_documents_to_outstanding).and_return(true)
        get :failed_validation, params: { person_id: person.id }

        expect(response).to have_http_status(:success)
        expect(response).to render_template("failed_validation")
      end
    end

    context "when unauthorized person id is passed in params" do
      let(:duplicate_person) { FactoryBot.create(:person, :with_consumer_role) }

      it "should fail pundit policy" do
        get :failed_validation, params: { person_id: duplicate_person.id }
        expect(response.status).to eq 302
      end
    end
  end

  describe 'invalid MIME types' do
    let(:user) { FactoryBot.create(:user, :consumer, person: person) }
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }

    before(:each) do
      sign_in user
      allow(user).to receive(:person).and_return(person)
      allow(controller).to receive(:authorize).and_return true
    end

    context 'GET new' do
      let(:request_double) { double }

      before do
        allow(Operations::Fdsh::Ridp::RequestPrimaryDetermination).to receive(:new).and_return(request_double)
        allow(request_double).to receive(:call).and_return(Failure('error'))
      end

      it 'returns success for html' do
        get :new
        expect(response).to redirect_to('/insured/fdsh_ridp_verifications/service_unavailable')
      end

      it 'returns failure for js' do
        get :new, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :new, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :new, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET primary_response' do
      let(:response_double) { double }
      let(:payload) { double(::Fdsh::Ridp::EligibilityResponseModel) }
      let(:serialized_payload) { { ridp_eligibility: {  event: 'event' } } }

      before do
        allow(controller).to receive(:find_response).with('primary').and_return(payload)
        allow(payload).to receive(:serializable_hash).and_return(serialized_payload)
        allow(Operations::Fdsh::Ridp::PrimaryResponseToInteractiveVerification).to receive(:new).and_return(response_double)
        allow(response_double).to receive(:call).and_return(Success('¡Éxito!'))
      end

      it 'returns success for html' do
        get :primary_response
        expect(response).to render_template('primary_response')
      end

      it 'returns failure for js' do
        get :primary_response, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :primary_response, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :primary_response, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET secondary_response' do
      let(:payload) { double(::Fdsh::Ridp::EligibilityResponseModel) }
      let(:serialized_payload) do
        {
          ridp_eligibility: {
            event: {
              attestations: {
                ridp_attestation: {
                  status: 'success',
                  evidences: [
                    {
                      secondary_response: {
                        Response: {
                          ResponseMetadata: {
                            TDSResponseDescriptionText: 'Good Job!'
                          },
                          VerificationResponse: {
                            DSHReferenceNumber: '12345'
                          }
                        }
                      }
                    }
                  ]
                }
              }
            }
          }
        }
      end

      before do
        allow(controller).to receive(:find_response).with('secondary').and_return(payload)
        allow(payload).to receive(:serializable_hash).and_return(serialized_payload)
      end

      it 'returns success for html' do
        get :secondary_response
        expect(response).to redirect_to(:help_paying_coverage_insured_consumer_role_index)
      end
    end

    context 'POST create' do
      let(:request_double) { double }

      before do
        allow(::IdentityVerification::InteractiveVerification).to receive(:new).and_return(request_double)
        allow(request_double).to receive(:valid?).and_return(false)
      end

      it 'returns success for html' do
        post :create, params: { interactive_verification: { session_id: '12345', transaction_id: '12345' } }
        expect(response).to render_template(:new)
      end

      it 'returns failure for js' do
        get :create, params: { interactive_verification: { session_id: '12345', transaction_id: '12345' } }, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :create, params: { interactive_verification: { session_id: '12345', transaction_id: '12345' } }, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :create, params: { interactive_verification: { session_id: '12345', transaction_id: '12345' } }, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET check_primary_response_received' do
      before do
        allow(controller).to receive(:received_response).with('primary').and_return(Success('success'))
      end

      it 'returns failure for html' do
        get :check_primary_response_received
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns success for js' do
        get :check_primary_response_received, xhr: true
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for json' do
        get :check_primary_response_received, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :check_primary_response_received, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET check_secondary_response_received' do
      before do
        allow(controller).to receive(:received_response).with('secondary').and_return(Success('success'))
      end

      it 'returns failure for html' do
        get :check_secondary_response_received
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns success for js' do
        get :check_secondary_response_received, xhr: true
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for json' do
        get :check_secondary_response_received, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :check_secondary_response_received, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET wait_for_primary_response' do
      it 'returns success for html' do
        get :wait_for_primary_response
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for js' do
        get :wait_for_primary_response, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :wait_for_primary_response, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :wait_for_primary_response, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET wait_for_secondary_response' do
      it 'returns success for html' do
        get :wait_for_secondary_response
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for js' do
        get :wait_for_secondary_response, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :wait_for_secondary_response, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :wait_for_secondary_response, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET service_unavailable' do
      it 'returns success for html' do
        get :service_unavailable
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for js' do
        get :service_unavailable, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :service_unavailable, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :service_unavailable, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'GET failed_validation' do
      it 'returns success for html' do
        get :failed_validation
        expect(response).to have_http_status(:success)
      end

      it 'returns failure for js' do
        get :failed_validation, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for json' do
        get :failed_validation, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns failure for xml' do
        get :failed_validation, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end
end

describe Insured::FdshRidpVerificationsController, "given an unauthorized user" do
  let(:mock_user) do
    instance_double(
      User,
      :has_hbx_staff_role? => false,
      :person => mock_person
    )
  end
  let(:mock_person) do
    double(
      policy_class: PersonPolicy,
      :agent? => false
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

  it "denies access to GET #service_unavailable" do
    get :service_unavailable
    expect(response.status).to eq 302
  end

  it "denies access to GET #failed_validation" do
    get :failed_validation
    expect(response.status).to eq 302
  end

  it "denies access to GET #wait_for_primary_response" do
    get :wait_for_primary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #wait_for_secondary_response" do
    get :wait_for_secondary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #check_primary_response_received" do
    get :check_primary_response_received
    expect(response.status).to eq 302
  end

  it "denies access to GET #check_secondary_response_received" do
    get :check_secondary_response_received
    expect(response.status).to eq 302
  end

  it "denies access to GET #primary_response" do
    get :primary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #secondary_response" do
    get :secondary_response
    expect(response.status).to eq 302
  end
end