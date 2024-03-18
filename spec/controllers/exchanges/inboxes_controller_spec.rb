require 'rails_helper'

RSpec.describe Exchanges::InboxesController do
  let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:message) do
    FactoryBot.create(
      :message,
      inbox: hbx_profile.inbox,
      folder: "sent",
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Hbx Profile Mailbox",
      subject: "Account link for message.",
      body: "<a href=''>Link to access message</a>  <br>"
    )
  end

  before :each do
    message
  end

  context 'admin' do
    let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:admin_user) { FactoryBot.create(:user, person: admin_person) }

    context 'with the correct permissions' do
      let(:permission) { FactoryBot.create(:permission, :super_admin) }

      before do
        admin_person.hbx_staff_role.update(permission_id: permission.id)
      end

      context "DELETE destroy" do
        it 'allows admin delete message' do
          sign_in admin_user
          delete :destroy, params: { :id => hbx_profile.id, :message_id => message.id }, xhr: true

          expect(response).to have_http_status(:success)
          expect(flash[:notice]).to be_present
          expect(flash[:notice]).to eq "Successfully deleted inbox message."
        end
      end

      context "GET show" do
        it 'allows admin to view message' do
          sign_in admin_user
          get :show, params: { :id => hbx_profile.id, :message_id => message.id }, xhr: true

          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'with the incorrect permissions' do
      let(:permission) { FactoryBot.create(:permission, :developer) }

      before do
        admin_person.hbx_staff_role.update(permission_id: permission.id)
      end

      context "DELETE destroy" do
        it 'does not allow developer-admin to delete message' do
          sign_in admin_user
          delete :destroy, params: { :id => hbx_profile.id, :message_id => message.id }, xhr: true

          expect(response).to have_http_status(403)
          expect(flash[:error]).to be_present
          expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.inbox?, (Pundit policy)"
        end
      end

      context "GET show" do
        it 'does not allow developer-admin to view message' do
          sign_in admin_user
          get :show, params: { :id => hbx_profile.id, :message_id => message.id }, xhr: true

          expect(response).to have_http_status(403)
          expect(message.message_read).to eq false
        end
      end
    end
  end

  context 'consumer role' do
    let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_user) { FactoryBot.create(:user, person: consumer_person) }

    context "DELETE destroy" do
      it 'does not allow user to delete message' do
        sign_in consumer_user
        delete :destroy, params: {:id => hbx_profile.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.inbox?, (Pundit policy)"
      end
    end

    context "GET show" do
      it 'does not allow user to view message' do
        sign_in consumer_user
        get :show, params: {:id => hbx_profile.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(message.message_read).to eq false
      end
    end
  end

  context 'broker role' do
    let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
    let(:broker_user) { FactoryBot.create(:user, person: broker_person) }

    context "DELETE destroy" do
      it 'does not allow user to delete message' do
        sign_in broker_user
        delete :destroy, params: {:id => hbx_profile.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.inbox?, (Pundit policy)"
      end
    end

    context "GET show" do
      it 'does not allow user to view message' do
        sign_in broker_user
        get :show, params: {:id => hbx_profile.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(message.message_read).to eq false
      end
    end
  end
end
