# frozen_string_literal: true

RSpec.describe FinancialAssistance::RelationshipsController, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:dependent_person) do
    pr = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    person.ensure_relationship_with(pr, 'spouse')
    pr
  end
  let(:dependent_member) { FactoryBot.create(:family_member, family: family, person: dependent_person) }

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

  let(:dependent_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      application: application,
      family_member_id: dependent_member.id,
      person_hbx_id: dependent_person.hbx_id
    )
  end

  before do
    dependent_applicant
    applicant
    person.consumer_role.move_identity_documents_to_verified
    sign_in(user)
    session[:person_id] = person.id
  end

  # index
  describe 'GET #index' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        get :index, params: { application_id: application.id }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end

  # create
  describe 'POST #create' do
    context 'when application is in renewal_draft state' do
      it 'redirects to applications index page' do
        post :create, params: {
          application_id: application.id,
          applicant_id: applicant.id,
          relative_id: dependent_applicant.id,
          kind: 'child'
        }
        expect(response).to redirect_to(applications_path)
        expect(flash[:alert]).to eq('This application cannot be edited as it is a renewal draft.')
      end
    end
  end
end
