# frozen_string_literal: true

RSpec.describe FinancialAssistance::RelationshipsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  describe 'pundit policy authorization checks' do
    after :all do
      DatabaseCleaner.clean
    end

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:primary_family_member) { family.primary_applicant }
    let(:dependent_person) do
      pr = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
      person.ensure_relationship_with(pr, 'spouse')
      pr
    end
    let(:dependent_member) { FactoryBot.create(:family_member, family: family, person: dependent_person) }
    let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
    let(:primary_applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application,
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

    let(:permission) { FactoryBot.create(:permission, :developer) }
    let(:developer_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user_with_developer_role) { FactoryBot.create(:user, person: developer_person) }

    before do
      developer_person.hbx_staff_role.update_attributes(permission_id: permission.id, subrole: permission.name)
      sign_in(user_with_developer_role)
      session[:person_id] = person.id
    end

    describe '#index' do
      let(:params) { { application_id: application.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          get :index, params: params
          expect(response).to redirect_to(app_root_path)
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/application_policy.index?, (Pundit policy)'
          )
        end
      end
    end

    describe '#create' do
      let(:params) do
        {
          kind: 'spouse',
          applicant_id: primary_applicant.id,
          relative_id: dependent_applicant.id,
          application_id: application.id
        }
      end

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          post :create, params: params, format: :js
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/application_policy.create?, (Pundit policy)'
          )
        end
      end
    end
  end
end

def app_root_path
  Rails.application.class.routes.url_helpers.root_path
end
