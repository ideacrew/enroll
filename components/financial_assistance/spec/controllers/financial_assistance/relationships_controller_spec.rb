# frozen_string_literal: true

RSpec.describe FinancialAssistance::RelationshipsController, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  describe 'Mime types' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
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

    let(:permission) { FactoryBot.create(:permission, :super_admin) }
    let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:admin_user) { FactoryBot.create(:user, person: admin_person) }

    before do
      admin_person.hbx_staff_role.update_attributes(permission_id: permission.id, subrole: permission.name)
      sign_in(admin_user)
      session[:person_id] = person.id
    end

    context 'GET #index' do
      let(:params) { { application_id: application.id } }

      it 'html request returns success' do
        get :index, params: params
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:success)
      end

      it 'js request returns failure' do
        get :index, params: params, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'json request returns failure' do
        get :index, params: params, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'xml request returns failure' do
        get :index, params: params, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end
end

def app_root_path
  Rails.application.class.routes.url_helpers.root_path
end
