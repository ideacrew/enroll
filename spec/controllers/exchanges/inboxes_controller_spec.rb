require 'rails_helper'

RSpec.describe Exchanges::InboxesController do
  let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:assister_person) { FactoryBot.create(:person, :with_assister_role)}
  let(:assister_user) { FactoryBot.create(:user, person: assister_person) }
  let(:message) do
    FactoryBot.create(
      :message,
      inbox: assister_person.inbox,
      folder: "inbox",
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Account link for  Test. ",
      body: "<a href=''>Link to access Test</a>  <br>"
    )
  end

  before :each do
    message
  end

  context 'assister role' do
    context "DELETE destroy" do
      it 'allows user to delete message' do
        sign_in assister_user
        delete :destroy, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(:success)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Successfully deleted inbox message."
        expect(message.folder).to eq "deleted"
      end
    end

    context "GET show" do
      it 'allows user to view message' do
        sign_in assister_user
        get :show, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(:success)
        expect(message.message_read).to eq true
      end
    end
  end

  context 'csr role' do
    let(:csr_person) { FactoryBot.create(:person, :with_csr_role)}
    let(:csr_user) { FactoryBot.create(:user, person: csr_person) }
    let(:message) do
      FactoryBot.create(
        :message,
        inbox: csr_person.inbox,
        folder: "inbox",
        sender_id: hbx_profile.id,
        parent_message_id: hbx_profile.id,
        from: 'Plan Shopping Web Portal',
        to: "Agent Mailbox",
        subject: "Account link for  Test. ",
        body: "<a href=''>Link to access Test</a>  <br>"
      )
    end

    context "DELETE destroy" do
      it 'allows user to delete message' do
        sign_in csr_user
        delete :destroy, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(:success)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Successfully deleted inbox message."
        expect(message.folder).to eq "deleted"
      end
    end

    context "GET show" do
      it 'allows user to view message' do
        sign_in csr_user
        get :show, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(:success)
        expect(message.message_read).to eq true
      end
    end
  end

  context 'consumer role' do
    let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_user) { FactoryBot.create(:user, person: consumer_person) }

    context "DELETE destroy" do
      it 'does not allow user to delete message' do
        sign_in consumer_user
        delete :destroy, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Access not allowed for agent_policy.inbox?, (Pundit policy)"
        expect(message.folder).to eq "inbox"
      end
    end

    context "GET show" do
      it 'does not allow user to view message' do
        sign_in consumer_user
        get :show, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

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
        delete :destroy, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Access not allowed for agent_policy.inbox?, (Pundit policy)"
        expect(message.folder).to eq "inbox"
      end
    end

    context "GET show" do
      it 'does not allow user to view message' do
        sign_in broker_user
        get :show, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(message.message_read).to eq false
      end
    end
  end

  context 'admin role' do
    let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:admin_user) { FactoryBot.create(:user, person: admin_person) }

    context "DELETE destroy" do
      it 'does not allow user to delete message' do
        sign_in admin_user
        delete :destroy, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Access not allowed for agent_policy.inbox?, (Pundit policy)"
        expect(message.folder).to eq "inbox"
      end
    end

    context "GET show" do
      it 'does not allow user to view message' do
        sign_in admin_user
        get :show, params: {:id => assister_person.inbox.id, :message_id => message.id}, xhr: true

        expect(response).to have_http_status(403)
        expect(message.message_read).to eq false
      end
    end
  end

  context "GET show / DELETE destroy" do
    let(:user) { double("User") }
    let(:person) { double("Person", agent?: false) }
    let(:hbx_profile) { double("HbxProfile") }
    let(:inbox) { double("Inbox") }
    let(:message){ double("Message", message_read: false ) }
    let(:inbox_provider){double(id: double("id"),full_name: double("inbox_provider"))}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(EnrollRegistry[:inbox_tab].feature).to receive(:is_enabled).and_return(true)
    end

    context "as user" do
      before :each do
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      end

      it "should render show" do
        get :show, params:{id: "test"}
        expect(response).to have_http_status(:success)
      end

      it "delete action" do
        delete :destroy, params:{id: 1}, xhr:true
        expect(response).to have_http_status(:success)
      end
    end

    context "as admin" do
      before do
        allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      end

      it "should render show" do
        get :show, params:{id: "test"}
        expect(response).to have_http_status(:success)
        expect(message.message_read).to eq(false)
      end
    end
  end
end
