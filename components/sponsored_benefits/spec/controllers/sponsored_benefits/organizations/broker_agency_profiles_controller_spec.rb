require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::BrokerAgencyProfilesController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    let!(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryGirl.create(:person, user: user_with_hbx_staff_role )}
    let(:broker_double) { double(id: '12345') }
    let(:current_person) { double(:current_person) }
    let(:broker_role) { double(:broker_role, broker_agency_profile_id: '5ac4cb58be0a6c3ef400009b') }
    let(:datatable) { double(:datatable) }
    let(:sponsor) { double(:sponsor, id: '5ac4cb58be0a6c3ef400009a', sic_code: '1111') }
    let(:active_user) { double(:has_hbx_staff_role? => false) }

    let!(:broker_organization) { create(:sponsored_benefits_organization, broker_agency_profile: broker_agency_profile) }
    let(:broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }

    let(:cca_employer_profile) {
      employer = build(:shop_cca_employer_profile)
      employer
    }

    context "#employers" do
      before do
        sign_in user_with_hbx_staff_role
        xhr :get, :employers, id: broker_agency_profile.id
      end

      it "should set datatable instance variable" do
        expect(assigns(:datatable).class).to eq Effective::Datatables::BrokerAgencyEmployerDatatable
      end
    end
  end
end
