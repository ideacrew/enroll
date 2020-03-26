require 'rails_helper'

RSpec.describe Employers::InboxesController, :type => :controller do
  let(:hbx_profile) { double(id: double("hbx_profile_id"))}
  let(:user) { double("user") }
  let(:person) { double(:employer_staff_roles => [double("person", :employer_profile_id => double)], agent?: false)}

  describe "Get new" do
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"), inbox: double(messages: double(build: double("inbox"))))}
    before do
      sign_in
      allow(EmployerProfile).to receive(:find).and_return(inbox_provider)
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
    end

    it "render new template" do
      get :new, params:{:id => inbox_provider.id, profile_id: hbx_profile.id, to: "test"}, format: :js, xhr:true
      expect(response).to render_template("new")
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST create" do
    let(:inbox){Inbox.new}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}
    let(:inbox_header) { {"subject"=>"test", "body"=>"test", "sender_id"=>"558b63ef4741542b64290000", "from"=>"HBXAdmin", "to"=>"Acme Inc."}}

    before do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      allow(EmployerProfile).to receive(:find).and_return(inbox_provider)
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(inbox_provider).to receive(:inbox).and_return(inbox)
      allow(inbox_provider.inbox).to receive(:post_message).and_return(inbox)
      allow(hbx_profile).to receive(:inbox).and_return(inbox)
    end

    it "creates new message" do
      allow(inbox_provider.inbox).to receive(:save).and_return(true)
      post :create, params: { message: inbox_header, id: inbox_provider.id, profile_id: hbx_profile.id}
      expect(response).to have_http_status(:redirect)
    end

    it "renders new" do
      allow(inbox_provider.inbox).to receive(:save).and_return(false)
      post :create, params: { message: inbox_header, id: inbox_provider.id, profile_id: hbx_profile.id}
      expect(response).to render_template(:new)
    end
  end

  describe "GET show / DELETE destroy" do
    let(:message){double(to_a: double("to_array"))}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}
    before do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      sign_in(user)
      allow(EmployerProfile).to receive(:find).and_return(inbox_provider)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
    end

    it "show action" do
      get :show, params:{id: 1}
      expect(response).to have_http_status(:success)
    end

    it "delete action" do
      delete :destroy, params:{id: 1}, xhr:true
      expect(response).to have_http_status(:success)
    end
  end

end
