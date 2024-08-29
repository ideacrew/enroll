# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::EvidencesController, type: :controller do
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

  let(:evidence) do
    applicant.create_income_evidence(
      key: :income,
      title: 'Income',
      aasm_state: 'outstanding',
      due_on: nil,
      verification_outstanding: false,
      is_satisfied: true
    )
  end

  before do
    person.consumer_role.move_identity_documents_to_verified
    sign_in(user)
  end

  # update_evidence
  describe 'POST #update_evidence' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        post :update_evidence, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          id: evidence.id,
          verification_reason: 'Expired',
          admin_action: 'verify'
        }

        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # fdsh_hub_request
  describe 'POST #fdsh_hub_request' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        post :fdsh_hub_request, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          id: evidence.id,
          admin_action: 'verify'
        }

        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # extend_due_date
  describe 'POST #extend_due_date' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        post :extend_due_date, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          id: evidence.id
        }

        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end
end
