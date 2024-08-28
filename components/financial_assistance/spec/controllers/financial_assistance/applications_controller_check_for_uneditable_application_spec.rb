# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:primary_family_member) { family.primary_applicant }
  let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'renewal_draft') }

  before do
    person.consumer_role.move_identity_documents_to_verified
    sign_in(user)
  end

  # edit
  describe 'GET #edit' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :edit, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # step
  describe 'GET #step' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :step, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # copy
  describe 'GET #copy' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :copy, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # application_year_selection
  describe 'GET #application_year_selection' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :application_year_selection, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # application_checklist
  describe 'GET #application_checklist' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :application_checklist, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # review_and_submit
  describe 'GET #review_and_submit' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :review_and_submit, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # review
  describe 'GET #review' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :review, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # raw_application
  describe 'GET #raw_application' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :raw_application, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # transfer_history
  describe 'GET #transfer_history' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :transfer_history, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # wait_for_eligibility_response
  describe 'GET #wait_for_eligibility_response' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :wait_for_eligibility_response, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # eligibility_results
  describe 'GET #eligibility_results' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :eligibility_results, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # application_publish_error
  describe 'GET #application_publish_error' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :application_publish_error, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # eligibility_response_error
  describe 'GET #eligibility_response_error' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :eligibility_response_error, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # check_eligibility_results_received
  describe 'GET #check_eligibility_results_received' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :check_eligibility_results_received, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # checklist_pdf
  describe 'GET #checklist_pdf' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :checklist_pdf, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # update_transfer_requested
  describe 'POST #update_transfer_requested' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        post :update_transfer_requested, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # update_application_year
  describe 'POST #update_application_year' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        post :update_application_year, params: { id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end
end
