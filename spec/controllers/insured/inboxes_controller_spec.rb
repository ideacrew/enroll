# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insured::InboxesController, :type => :controller do
  let(:hbx_profile) { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  # Need to generate an actual inbox for the authorization with InboxPolicy
  let(:inbox) { FactoryBot.create(:inbox, :with_message, recipient: person) }
  let(:message) { inbox.messages.first }

  # This is used for all CREATE methods
  let(:valid_params) { {'subject' => 'test', 'body' => 'test', 'sender_id' => '558b63ef4741542b64290000', 'from' => 'HBXAdmin', 'to' => 'Acme Inc.'} }

  before do
    allow(person).to receive(:user).and_return(user)
  end

  context 'consumer' do
    context 'with permissions' do
      before do
        sign_in(user)
      end

      describe 'GET new / post CREATE' do
        it 'will render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('new')
          expect(response).to have_http_status(:success)
        end

        it 'will create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Successfully sent message.")
        end

        it 'will render new if message params invalid' do
          valid_params['subject'] = nil
          valid_params['body'] = nil
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }, format: :js, xhr: true

          expect(response).to render_template('new')
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will show specific message' do
          get :show, params: { id: person.id, message_id: message.id }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('show')
          expect(response).to have_http_status(:success)
        end

        it 'will delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'with incorrct mime types' do
      before do
        sign_in(user)
      end

      context 'GET new' do
        it 'html will render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }
          expect(response).to have_http_status(:success)
        end

        it 'json request will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it 'xml request will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end

      context 'POST create' do
        it 'json request will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it 'xml request will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end

      context 'DELETE destroy' do
        it 'html request will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }
          expect(response).to have_http_status(:not_acceptable)
        end

        it 'json request will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it 'xml request will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    context 'without permissions' do
      let(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:fake_user) { FactoryBot.create(:user, person: fake_person) }
      let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }

      before do
        sign_in(fake_user)
      end

      describe 'GET new / post CREATE' do
        it 'will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will not show specific message' do
          get :show, params: { id: person.id, message_id: message.id }

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end
    end
  end

  context 'admin' do
    let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let!(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: admin_person) }

    context 'with permissions' do
      let!(:permission) { FactoryBot.create(:permission, :super_admin) }
      let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

      before do
        sign_in(admin_user)
      end

      describe 'GET new / post CREATE' do
        it 'will render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('new')
          expect(response).to have_http_status(:success)
        end

        it 'will create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Successfully sent message.")
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will show specific message' do
          get :show, params: { id: person.id, message_id: message.id }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('show')
          expect(response).to have_http_status(:success)
        end

        it 'will delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'without permissions' do
      let!(:invalid_permission) { FactoryBot.create(:permission, :developer) }
      let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: invalid_permission.id) }

      before do
        sign_in(admin_user)
      end

      describe 'GET new / post CREATE' do
        it 'will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will not show specific message' do
          get :show, params: { id: person.id, message_id: message.id }, xhr: true, format: :js

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end
    end
  end

  context 'broker' do
    let!(:broker_user) {FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role'])}
    let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
    let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
    let(:assister)  do
      assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00")
      assister.save(validate: false)
      assister
    end

    context 'with permissions/hired by family' do
      before do
        family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                            writing_agent_id: writing_agent.id,
                                                                                            start_on: Time.now,
                                                                                            is_active: true)
        sign_in(broker_user)
      end

      describe 'GET new / post CREATE' do
        it 'will render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('new')
          expect(response).to have_http_status(:success)
        end

        it 'will create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:redirect)
          expect(flash[:notice]).to eq("Successfully sent message.")
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will show specific message' do
          get :show, params: { id: person.id, message_id: message.id }

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to render_template('show')
          expect(response).to have_http_status(:success)
        end

        it 'will delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_truthy
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'without permissions/not hired by family' do
      before do
        sign_in(broker_user)
      end

      describe 'GET new / post CREATE' do
        it 'will not render :new' do
          get :new, params: { id: person.id, profile_id: hbx_profile.id, to: 'test' }, format: :js, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not create a new message' do
          post :create, params: { id: person.id, profile_id: hbx_profile.id, message: valid_params }

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end

      describe 'GET show / DELETE destroy' do
        it 'will not show specific message' do
          get :show, params: { id: person.id, message_id: message.id }

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end

        it 'will not delete a message' do
          delete :destroy, params: { id: person.id, message_id: message.id }, xhr: true

          expect(assigns(:inbox_provider).present?).to be_falsey
          expect(response).to have_http_status(403)
          expect(flash[:error]).to eq("Access not allowed for family_policy.legacy_show?, (Pundit policy)")
        end
      end
    end
  end
end
