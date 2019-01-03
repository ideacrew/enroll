require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let(:bap_id) { organization.broker_agency_profile.id }
    let!(:new_person_for_staff) { FactoryGirl.create(:person) }
    let!(:new_person_for_staff1) { FactoryGirl.create(:person) }
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff1 ) }
    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "GET new" do

      before do
        xhr :get, :new
      end


      it "should render new template" do
        expect(response).to render_template("new")
      end

      it "should initialize staff" do
        expect(assigns(:staff).class).to eq staff_class
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST create", dbclean: :after_each do

      context "creating staff role with existing person params" do

        let!(:staff_params) {
          {
              profile_type: "broker_agency_staff",
              :staff => {:first_name => new_person_for_staff.first_name, :last_name => new_person_for_staff.last_name, :dob => new_person_for_staff.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        }

        before :each do
          post :create, staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          expect(response.location.include?("new")).to eq true
        end

        it "should get an notice" do
          expect(flash[:notice]).to match /Broker Staff Role added sucessfully/
        end
      end

      context "person is already assigned as a staff to broker" do

        let!(:staff_params) {
          {
              profile_type: "broker_agency_staff",
              :staff => {:first_name => new_person_for_staff1.first_name, :last_name => new_person_for_staff1.last_name, :dob => new_person_for_staff1.dob, email: "hello@hello.com",  :profile_id => bap_id}

          }
        }

        before :each do
          post :create, staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          expect(response.location.include?("new")).to eq true
        end

        it "should get an notice" do
          expect(flash[:error]).to match /Broker Staff Role was not added because You are already associated with the Broker Agency/
        end
      end

      context "creating staff role with new person params" do

        let!(:staff_params) {
          {
              profile_type: "broker_agency_staff",
              :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => bap_id}

          }
        }

        before :each do
          post :create, staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          expect(response.location.include?("new")).to eq true
        end

        it "should get an notice" do
          expect(flash[:notice]).to match /Broker Staff Role added sucessfully/
        end
      end
    end
  end
end
