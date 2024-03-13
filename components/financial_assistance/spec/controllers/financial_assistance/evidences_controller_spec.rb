# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::EvidencesController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let(:mock_consumer_role) { instance_double("ConsumerRole", id: "test") }
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let(:family_id) { BSON::ObjectId.new }
  let(:family_member_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: 'draft',effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryBot.create(:applicant, application: application,family_member_id: family_member_id) }
  let(:evidence) do
    applicant.create_income_evidence(
      key: :income,
      title: 'Income',
      aasm_state: 'pending',
      due_on: nil,
      verification_outstanding: false,
      is_satisfied: true
    )
  end
  let!(:params) { { "applicant_id" => applicant.id, "application_id" => application.id, "evidence_kind" => evidence, "admin_action" => 'verify' } }

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #update_evidence' do
    before do
      allow(FinancialAssistance::Evidence).to receive(:find).and_return(evidence)
    end

    context 'when update reason is included in reasons list' do
      before do
        get :update_evidence, params: params
      end

      it 'sets a success flash message' do
        expect(flash[:success]).to be_present
      end

      it 'redirects to verification_insured_families_path' do
        expect(response).to redirect_to verification_insured_families_path
      end
    end

    context 'when update reason is not included in reasons list' do
      before do
        get :update_evidence, params: params
      end

      it 'sets an error flash message' do
        expect(flash[:error]).to eq 'Please provide a verification reason.'
      end

      it 'redirects to verification_insured_families_path' do
        expect(response).to redirect_to verification_insured_families_path
      end
    end
  end

  describe 'GET #fdsh_hub_request' do
    context 'when the request determination is successful' do
      before do
        allow(FinancialAssistance::Evidence).to receive(:find).and_return(evidence)
        allow(evidence).to receive(:request_determination).and_return(true)
        get :fdsh_hub_request, params: params
      end

      it 'sets a success flash message' do
        expect(flash[:success]).to eq 'request submitted successfully'
      end

      it 'redirects to verification_insured_families_path' do
        expect(response).to redirect_to verification_insured_families_path
      end
    end

    context 'when the request determination is not successful' do
      before do
        allow(evidence).to receive(:request_determination).and_return(false)
        allow(controller).to receive(:current_user).and_return(user)
        get :fdsh_hub_request, params: params
      end

      it 'sets an error flash message' do
        expect(flash[:error]).to eq 'unable to submit request'
      end

      it 'redirects to verification_insured_families_path' do
        expect(response).to redirect_to verification_insured_families_path
      end
    end
  end

  context 'extend_due_date' do
    it "" do

    end
  end

  describe '#find_docs_owner' do
    context 'when applicant_id is provided' do
      before do
        allow(::FinancialAssistance::Applicant).to receive(:find).with(applicant.id.to_s).and_return(applicant)
        controller.params = { applicant_id: applicant.id.to_s }
        controller.send(:find_docs_owner)
      end

      it 'finds the applicant' do
        expect(controller.instance_variable_get(:@docs_owner)).to eq(applicant)
      end
    end

    context 'when applicant_id is not provided' do
      before do
        controller.params = {}
        controller.send(:find_docs_owner)
      end

      it 'does not find an applicant' do
        expect(controller.instance_variable_get(:@docs_owner)).to be_nil
      end
    end
  end

  describe '#find_type' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:fetch_applicant).and_return(applicant)
      allow(controller).to receive(:find_docs_owner).and_return(evidence)
      allow(controller).to receive(:params).and_return({ evidence_kind: 'evidence' })
      allow_any_instance_of(ApplicationPolicy).to receive(:edit?).and_return(true)
    end

    context 'when the applicant is authorized' do
      it 'assigns the correct evidence' do
        get :fdsh_hub_request, params: params
        expect(assigns(:evidence)).to eq(applicant.some_kind)
      end
    end

    context 'when the applicant is not authorized' do
      before do
        # This simulates the applicant not being authorized
        allow_any_instance_of(ApplicationPolicy).to receive(:edit?).and_return(false)
      end

      it 'raises a Pundit::NotAuthorizedError' do
        expect { get :fdsh_hub_request, params: params }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe '#fetch_applicant_succeeded?' do
    context 'when @applicant is present' do
      before do
        controller.instance_variable_set(:@applicant, applicant)
      end

      it 'returns true' do
        expect(controller.send(:fetch_applicant_succeeded?)).to eq(true)
      end
    end

    context 'when @applicant is not present' do
      before do
        controller.instance_variable_set(:@applicant, nil)
      end

      it 'logs an error and returns false' do
        expect(controller).to receive(:log).with(hash_including(message: 'Application Exception - applicant required'), severity: 'error')
        expect(controller.send(:fetch_applicant_succeeded?)).to eq(false)
      end
    end
  end

  describe '#fetch_applicant' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'when applicant_id is present in params' do
      it 'assigns the applicant' do
        get :fdsh_hub_request, params: params
        expect(assigns(:applicant)).to eq(applicant)
      end
    end

    context 'when current user is an agent and person_id is in session' do
      before do
        session[:person_id] = applicant.id
      end

      it 'assigns the applicant' do
        get :fdsh_hub_request, params: params
        expect(assigns(:applicant)).to eq(applicant)
      end
    end
  end
end