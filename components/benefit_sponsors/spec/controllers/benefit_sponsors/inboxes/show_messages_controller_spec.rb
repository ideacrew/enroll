# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Inboxes::MessagesController, type: :controller do
  routes { BenefitSponsors::Engine.routes }

  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:user_of_family) { FactoryBot.create(:user, person: person) }
  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :normal_ivl_open_enrollment,
      us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
      cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0"
    )
  end
  let(:hbx_staff_person) { FactoryBot.create(:person) }
  let(:hbx_staff_role) do
    hbx_staff_person.create_hbx_staff_role(
      permission_id: permission.id,
      subrole: permission.name,
      hbx_profile: hbx_profile
    )
  end
  let(:hbx_admin_user) do
    FactoryBot.create(:user, person: hbx_staff_person)
    hbx_staff_role.person.user
  end

  let(:market_kind) { :both }
  let(:broker_person) { FactoryBot.create(:person) }
  let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
  let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
  let(:message) { FactoryBot.create(:message, :inbox_folder, inbox: broker_person.inbox) }

  let(:site) do
    FactoryBot.create(
      :benefit_sponsors_site,
      :with_benefit_market,
      :as_hbx_profile,
      site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
    )
  end

  let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
  let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
  let(:broker_agency_id) { broker_agency_profile.id }

  let(:logged_in_user) { broker_user }

  let(:broker_agency_account) do
    family.broker_agency_accounts.create!(
      benefit_sponsors_broker_agency_profile_id: broker_agency_id,
      writing_agent_id: broker_role.id,
      is_active: baa_active,
      start_on: TimeKeeper.date_of_record
    )
  end

  let(:broker_staff_person) { FactoryBot.create(:person) }

  let(:broker_staff_state) { 'active' }

  let(:broker_staff) do
    FactoryBot.create(
      :broker_agency_staff_role,
      person: broker_staff_person,
      aasm_state: broker_staff_state,
      benefit_sponsors_broker_agency_profile_id: broker_agency_id
    )
  end
  let(:broker_staff_user) { FactoryBot.create(:user, person: broker_staff_person) }

  let(:permission) { FactoryBot.create(:permission, :super_admin) }

  before do
    broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
    broker_person.create_broker_agency_staff_role(
      benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
    )
    broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
    broker_role.approve!
    broker_staff
  end

  describe "GET #show" do
    context 'broker logged in' do
      let(:logged_in_user) { broker_user }

      it 'succesfully deletes the message' do
        sign_in logged_in_user
        get :show, params: { id: broker_role.person.id, message_id: message.id }
        expect(message.reload.folder).to eq(Message::FOLDER_TYPES[:inbox])
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end
    end

    context 'active broker staff logged in' do
      let(:logged_in_user) { broker_staff_user }

      it 'succesfully deletes the message' do
        sign_in logged_in_user
        get :show, params: { id: broker_role.person.id, message_id: message.id }
        expect(message.reload.folder).to eq(Message::FOLDER_TYPES[:inbox])
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end
    end

    context 'inactive broker staff logged in' do
      let(:broker_staff_state) { 'broker_agency_terminated' }
      let(:logged_in_user) { broker_staff_user }

      it 'denies access to inactive broker staff' do
        sign_in logged_in_user
        get :show, params: { id: broker_role.person.id, message_id: message.id, format: :js }
        expect(response.status).to eq(403)
        expect(flash[:error]).to eq('Access not allowed for show_inbox_message?, (Pundit policy)')
      end
    end

    context 'hbx staff admin with super_admin role logged in' do
      let(:logged_in_user) { hbx_admin_user }

      it 'succesfully deletes the message' do
        sign_in logged_in_user
        get :show, params: { id: broker_role.person.id, message_id: message.id }
        expect(message.reload.folder).to eq(Message::FOLDER_TYPES[:inbox])
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end
    end

    context 'hbx staff admin with developer role logged in' do
      let(:permission) { FactoryBot.create(:permission, :developer) }
      let(:logged_in_user) { hbx_admin_user }

      it 'denies access to inactive broker staff' do
        sign_in logged_in_user
        get :show, params: { id: broker_role.person.id, message_id: message.id, format: :js }
        expect(response.status).to eq(403)
        expect(flash[:error]).to eq('Access not allowed for show_inbox_message?, (Pundit policy)')
      end
    end
  end
end
