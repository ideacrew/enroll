

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::HbxProfilesController, dbclean: :around_each do
  
describe "GET dry_run_dashboard" do
  let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let!(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
  let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }
  let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family.id, aasm_state: 'determined' }

  before(:each) do
    sign_in(admin_user)
  end

  context "with valid user" do
    let!(:permission) { FactoryBot.create(:permission, :super_admin) }

    context "when the request type is invalid" do
      it "should not render the dry_run_dashboard template" do
        get :dry_run_dashboard, format: :csv
        expect(response.status).to eq 406
      end
    end

    context "when the request type is valid" do
      it "should render success" do
        get :dry_run_dashboard, format: :html
        expect(response.status).to eq 200
      end
    end
  end

  context "with invalid user" do
    let!(:permission) { FactoryBot.create(:permission, :developer) }

    it "should redirect to root path" do
      get :dry_run_dashboard
      expect(response.status).to eq 302
    end
  end
end