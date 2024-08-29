# frozen_string_literal: true

RSpec.describe FinancialAssistance::VerificationDocumentsController, type: :controller do
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

  # upload
  describe 'POST #upload' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        post :upload, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          evidence: evidence.id,
          evidence_kind: 'income_evidence'
        }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # download
  describe 'GET #download' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        get :download, params: { application_id: application.id, applicant_id: applicant.id, id: evidence.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end

  # destroy
  describe 'DELETE #destroy' do
    context 'when application is in renewal_draft state' do
      it 'redirects to insured families verification page' do
        delete :destroy, params: { application_id: application.id, applicant_id: applicant.id, id: evidence.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq(l10n('faa.flash_alerts.uneditable_application'))
      end
    end
  end
end
