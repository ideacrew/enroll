# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicantsController, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:primary_family_member) { family.primary_applicant }
  let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'renewal_draft') }
  let(:applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      application: application,
      is_primary_applicant: true,
      family_member_id: primary_family_member.id,
      person_hbx_id: person.hbx_id
    )
  end

  before do
    person.consumer_role.move_identity_documents_to_verified
    sign_in(user)
  end

  # new
  describe 'GET #new' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :new, params: { application_id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # create
  describe 'POST #create' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        post :create, params: { application_id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # edit
  describe 'GET #edit' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :edit, params: { application_id: application.id, id: applicant.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # update
  describe 'PUT #update' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        put :update, params: { application_id: application.id, id: applicant.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # other_questions
  describe 'GET #other_questions' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :other_questions, params: { application_id: application.id, id: applicant.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # save_questions
  describe 'POST #save_questions' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        post :save_questions, params: { application_id: application.id, id: applicant.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # step
  describe 'GET #step' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :step, params: { application_id: application.id, id: applicant.id, step: 'step' }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # age_of_applicant
  describe 'GET #age_of_applicant' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :age_of_applicant, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          format: :js
        }, xhr: true
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # applicant_is_eligible_for_joint_filing
  describe 'GET #applicant_is_eligible_for_joint_filing' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :applicant_is_eligible_for_joint_filing, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          format: :text
        }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # immigration_document_options
  describe 'GET #immigration_document_options' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :immigration_document_options, params: { application_id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # destroy
  describe 'DELETE #destroy' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        delete :destroy, params: { application_id: application.id, id: applicant.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end
end
