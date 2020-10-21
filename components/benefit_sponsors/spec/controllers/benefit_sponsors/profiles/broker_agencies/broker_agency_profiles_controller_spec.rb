require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyProfilesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let!(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryGirl.create(:person, user: user_with_hbx_staff_role )}
    let!(:person01) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person01 ) }

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let(:bap_id) { organization.broker_agency_profile.id }

    before :each do
      person01.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: organization.broker_agency_profile.id)
      allow(organization.broker_agency_profile).to receive(:primary_broker_role).and_return(person01.broker_role)
      user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
      user_with_hbx_staff_role.person.hbx_staff_role.save!
    end

    describe "for broker_agency_profile's index" do
      context "index for user with admin_role(on successful pundit)" do
        before :each do
          sign_in(user_with_hbx_staff_role)
          get :index
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end

        it "should render the index template" do
          expect(response).to render_template("index")
        end
      end

      context "index for user with broker_role(on failed pundit)" do
        before :each do
          sign_in(user_with_broker_role)
          get :index
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end

        it "should rendirect to registration's new with broker_agency in params" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
        end
      end

      context "index for user with broker_agency_staff_role(on failed pundit)" do
        let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: organization.broker_agency_profile.id, person: person01) }

        before :each do
          user_with_broker_role.roles << "broker_agency_staff"
          user_with_broker_role.save!
          sign_in(user_with_broker_role)
          get :index
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end

        it "should redirect to controller's show with broker_agency_profile's id" do
          expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => bap_id))
        end
      end
    end

    describe "for broker_agency_profile's show" do
      context "for show with a broker_agency_profile_id and with a valid user" do
        before :each do
          sign_in(user_with_hbx_staff_role)
          allow(controller).to receive(:set_flash_by_announcement).and_return(true)
          get :show, id: bap_id
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end

        it "should render the index template" do
          expect(response).to render_template("show")
        end
      end

      context "for show with a broker_agency_profile_id and without a user" do
        before :each do
          get :show, id: bap_id
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end

        it "should redirect to the user's signup" do
          expect(response.location.include?('users/sign_up')).to be_truthy
        end
      end

      context 'for show with other broker_agency_profile_id and with a correct user' do
        let!(:organization1) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
        let(:bap_id1) {organization1.broker_agency_profile.id}

        before :each do
          sign_in(user_with_broker_role)
          allow(controller).to receive(:set_flash_by_announcement).and_return(true)
          get :show, id: bap_id1
        end

        it 'should not return success http status' do
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    describe "for broker_agency_profile's family_index" do
      context "with a valid user and with broker_agency_profile_id(on successful pundit)" do
        before :each do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :family_index, id: bap_id
        end

        it "should render family_index template" do
          expect(response).to render_template("benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/family_index")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context "with an invalid user and with broker_agency_profile_id(on falied pundit)" do
        let!(:user_without_person) { FactoryGirl.create(:user, :with_hbx_staff_role) }

        before :each do
          sign_in(user_without_person)
          xhr :get, :family_index, id: bap_id
        end

        it "should redirect to new of registration's controller for broker_agency" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end
      end
    end

    describe "for broker_agency_profile's staff_index" do
      context "with a valid user" do
        before :each do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :staff_index, id: bap_id
        end

        it "should return success http status" do
          expect(response).to have_http_status(:success)
        end

        it "should render staff_index template" do
          expect(response).to render_template("benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/staff_index")
        end
      end

      context "without a valid user" do
        let!(:user) { FactoryGirl.create(:user, roles: [], person: FactoryGirl.create(:person)) }

        before :each do
          sign_in(user)
          xhr :get, :staff_index, id: bap_id
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end

        it "should redirect to new of registration's controller for broker_agency" do
          expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
        end
      end
    end

    describe "family_datatable" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees with benefits"

      let!(:broker_agency_accounts) { FactoryGirl.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: organization.profiles.first, benefit_sponsorship: benefit_sponsorship) }
      let!(:user) { FactoryGirl.create(:user, roles: [], person: FactoryGirl.create(:person)) }
      let!(:ce) { benefit_sponsorship.census_employees.first }
      let!(:ee_person) { FactoryGirl.create(:person, :with_employee_role, :with_family, first_name: ce.first_name, last_name: ce.last_name, dob: ce.dob, ssn: ce.ssn, gender: ce.gender) }

      context "should return sucess and family" do
        before :each do
          ce.employee_role_id = ee_person.employee_roles.first.id
          ce.save
          ee_person.employee_roles.first.census_employee_id = ce.id
          ee_person.save
          DataTablesInQuery = Struct.new(:draw, :skip, :take, :search_string)
          dt_query = DataTablesInQuery.new("1", 0, 10, "")
          sign_in(user_with_hbx_staff_role)
          allow(controller).to receive(:extract_datatable_parameters).and_return(dt_query)
          xhr :get, :family_datatable, id: bap_id
          @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization.profiles.first.id)
        end

        it "should return a family" do
          expect(@query.total_count).not_to eq 0
        end

        it "should return success http status" do
          expect(response).to have_http_status(:success)
        end
      end

      context "should not return sucess" do
        before :each do
          sign_in(user)
          xhr :get, :family_datatable, id: bap_id
        end

        it "should not return sucess http status" do
          expect(response).not_to have_http_status(:success)
        end
      end

      context "should not return family" do
        before :each do
          ce.employee_role_id = ee_person.employee_roles.first.id
          ce.save
          ee_person.employee_roles.first.census_employee_id = ce.id
          ee_person.save
          benefit_sponsorship.broker_agency_accounts.first.update_attributes(is_active: false)
          DataTablesInQuery = Struct.new(:draw, :skip, :take, :search_string)
          dt_query = DataTablesInQuery.new("1", 0, 10, "")
          sign_in(user_with_hbx_staff_role)
          allow(controller).to receive(:extract_datatable_parameters).and_return(dt_query)
          xhr :get, :family_datatable, id: bap_id
          @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization.profiles.first.id)
        end

        it "should not return family" do
          expect(@query.total_count).to eq 0
        end
      end
    end
  end
end
