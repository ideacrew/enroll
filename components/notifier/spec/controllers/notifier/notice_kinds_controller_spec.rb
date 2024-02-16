require 'rails_helper'

RSpec.describe Notifier::NoticeKindsController, dbclean: :around_each do
  routes { Notifier::Engine.routes }

  describe "index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person", agent?: true)}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile")}
    let(:permission) { double("permission", can_view_notice_templates: true) }

    before :each do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(hbx_staff_role).to receive(:permission).and_return(permission)
      sign_in(user)
    end
    
    context "with notices tab feature enabled" do

      before do
        allow(EnrollRegistry[:notices_tab].feature).to receive(:is_enabled).and_return(true)
      end

      it "successfully renders index" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "with notices tab feature disabled" do
      before do
        allow(EnrollRegistry[:notices_tab].feature).to receive(:is_enabled).and_return(false)
      end

      it "redirects to exchanges root path" do
        get :index
        expect(response).to redirect_to(main_app.exchanges_hbx_profiles_root_path)
      end

      it "renders flash message" do
        get :index
        expect(flash[:alert]).to eql(l10n('insured.notices_tab_disabled_warning_message'))
      end
    end
  end
end

def main_app
  Rails.application.class.routes.url_helpers
end