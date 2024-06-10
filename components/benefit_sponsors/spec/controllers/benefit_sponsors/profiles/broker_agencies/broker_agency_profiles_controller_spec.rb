# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

# spec for Profiles::BrokerAgencies::BrokerAgencyProfilesController
module BenefitSponsors # rubocop:disable Metrics/ModuleLength
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyProfilesController, type: :controller, dbclean: :after_each do

    before :all do
      DatabaseCleaner.clean
    end

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role)}
    let!(:person01) { FactoryBot.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person01) }

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization1)                 { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:organization2)                 { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency1)                 { organization1.broker_agency_profile }
    let(:broker_agency2)                 { organization2.broker_agency_profile }

    let(:bap_id) { broker_agency1.id }
    let(:bap_id2) { broker_agency2.id }
    let(:super_permission) { FactoryBot.create(:permission, :super_admin) }
    let(:dev_permission) { FactoryBot.create(:permission, :developer) }

    let(:initialize_and_login_admin) do
      lambda { |permission|
        user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id, permission_id: permission.id)
        user_with_hbx_staff_role.person.hbx_staff_role.save!
        sign_in(user_with_hbx_staff_role)
      }
    end

    let(:initialize_and_login_broker) do
      lambda { |org|
        person01.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: org.broker_agency_profile.id, aasm_state: 'active')
        allow(org.broker_agency_profile).to receive(:primary_broker_role).and_return(person01.broker_role)
      # all brokers in an agency also have a 'broker_agency_staff_role'
        role = person01.create_broker_agency_staff_role({benefit_sponsors_broker_agency_profile_id: org.broker_agency_profile.id, aasm_state: 'active'})
        role.broker_agency_accept!
        sign_in(user_with_broker_role)
      }
    end

    let(:initialize_and_login_broker_agency_staff) do
      lambda { |org|
        role = person01.create_broker_agency_staff_role({benefit_sponsors_broker_agency_profile_id: org.broker_agency_profile.id, aasm_state: 'active'})
        role.broker_agency_accept!
        sign_in(user_with_broker_role)
      }
    end

    describe "#index" do
      context "admin" do
        context 'with the correct permissions' do
          before do
            initialize_and_login_admin[super_permission]
            get :index
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the index template" do
            expect(response).to render_template("index")
          end
        end

        context 'with the incorrect permissions' do
          before do
            initialize_and_login_admin[dev_permission]
            get :index
          end

          it "should return redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should not render the index template" do
            expect(response).to_not render_template("index")
          end
        end
      end

      context "broker" do
        before :each do
          initialize_and_login_broker[organization1]
          get :index
        end

        it "should not return success http status" do
          expect(response).to_not have_http_status(:success)
        end

        it "should redirect to controller's show with broker_agency_profile's id" do
          expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => bap_id))
        end
      end

      context "broker agency staff" do
        before :each do
          initialize_and_login_broker_agency_staff[organization1]
          get :index
        end

        it "should not return success http status" do
          expect(response).not_to have_http_status(:success)
        end

        it "should redirect to controller's show with broker_agency_profile's id" do
          expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => bap_id))
        end
      end

      context 'with the incorrect MIME type' do
        before do
          initialize_and_login_admin[super_permission]
        end

        it "js should return http success" do
          get :index, format: :js
          expect(response).to have_http_status(:success)
        end

        it "json should return http success" do
          get :index, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should return http success" do
          get :index, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    describe "#show" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :show, params: { id: bap_id }
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the show template" do
            expect(response).to render_template("show")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :show, params: { id: bap_id }
          end

          it "should return http redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should render the show template" do
            expect(response).to_not render_template("show")
          end
        end

        context "with an invalid MIME type" do
          before :each do
            initialize_and_login_admin[super_permission]
          end

          it 'js returns a failure' do
            get :show, params: { id: bap_id }, format: :js
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'json returns a failure' do
            get :show, params: { id: bap_id }, format: :json
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'xml returns a failure' do
            get :show, params: { id: bap_id }, format: :xml
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :show, params: { id: bap_id }
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the show template" do
            expect(response).to render_template("show")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :show, params: { id: bap_id }
          end

          it "should not render the show template" do
            expect(response).to_not render_template("show")
          end

          it "should redirect to controller's show with broker_agency_profile's id" do
            expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => bap_id2))
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :show, params: { id: bap_id }
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the show template" do
            expect(response).to render_template("show")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :show, params: { id: bap_id }
          end

          it "should redirect to controller's show with broker_agency_profile's id" do
            expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => bap_id2))
          end

          it "should not render the show template" do
            expect(response).to_not render_template("show")
          end
        end
      end
    end

    describe "#staff_index" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :staff_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the staff_index template" do
            expect(response).to render_template("staff_index")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :staff_index, params: { id: bap_id }, xhr: true
          end

          it "should return not assign a staff var" do
            expect(assigns(:staff)).to eq(nil)
          end

          it "should not render the staff_index template" do
            expect(response).to_not render_template("staff_index")
          end
        end
      end

      context "broker" do
        before :each do
          initialize_and_login_broker[organization1]
          get :staff_index, params: { id: bap_id }
        end

        it "should not return http success" do
          expect(response).to_not have_http_status(:success)
        end

        it "should not render the staff_index template" do
          expect(response).to_not render_template("staff_index")
        end
      end

      context "broker staff" do
        before :each do
          initialize_and_login_broker_agency_staff[organization2]
          get :staff_index, params: { id: bap_id }
        end

        it "should return not assign a staff var" do
          expect(assigns(:staff)).to eq(nil)
        end

        it "should not render the staff_index template" do
          expect(response).to_not render_template("staff_index")
        end
      end
    end

    describe "#family_datatable" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees with benefits"

      let!(:broker_agency_accounts) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: organization1.profiles.first, benefit_sponsorship: benefit_sponsorship) }
      let!(:user) { FactoryBot.create(:user, roles: [], person: FactoryBot.create(:person)) }
      let!(:ce) { benefit_sponsorship.census_employees.first }
      let!(:ee_person) { FactoryBot.create(:person, :with_employee_role, :with_family, first_name: ce.first_name, last_name: ce.last_name, dob: ce.dob, ssn: ce.ssn, gender: ce.gender) }

      before :each do
        ce.employee_role_id = ee_person.employee_roles.first.id
        ce.save
        ee_person.employee_roles.first.census_employee_id = ce.id
        ee_person.save

        # changing the struct to fit rubocop's specifications breaks the query -> overriding for this test
        data_tables_in_query = Struct.new(:draw, :skip, :take, :search_string) # rubocop:disable Lint/StructNewOverride
        dt_query = data_tables_in_query.new("1", 0, 10, "")

        allow(controller).to receive(:extract_datatable_parameters).and_return(dt_query)
      end

      context 'admin' do
        context 'with the correct permissions' do
          context 'should return family and success' do
            before do
              initialize_and_login_admin[super_permission]
              post :family_datatable, params: { id: bap_id }, xhr: true
              @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization1.profiles.first.id, organization1.profiles.first.market_kind)
            end

            it "should return a family" do
              expect(@query.total_count).not_to eq 0
            end

            it "should return success http status" do
              expect(response).to have_http_status(:success)
            end
          end

          context "should not return family if agency is inactive" do
            before :each do
              benefit_sponsorship.broker_agency_accounts.first.update_attributes(is_active: false)

              initialize_and_login_admin[super_permission]
              post :family_datatable, params: { id: bap_id }, xhr: true
              @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization1.profiles.first.id, organization1.profiles.first.market_kind)
            end

            it "should not return family" do
              expect(@query.total_count).to eq 0
            end
          end
        end

        context 'with the incorrect permissions' do
          before do
            initialize_and_login_admin[dev_permission]
            post :family_datatable, params: { id: bap_id }, xhr: true
            @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization1.profiles.first.id, organization1.profiles.first.market_kind)
          end

          it "should not be a success" do
            expect(response.status).to_not have_http_status(:success)
          end
        end

        context 'with invalid MIME type' do
          before do
            initialize_and_login_admin[super_permission]
          end

          it 'html should return an error' do
            post :family_datatable, params: { id: bap_id }
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'html should return an error' do
            post :family_datatable, params: { id: bap_id }, format: :js
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'html should return an error' do
            post :family_datatable, params: { id: bap_id }, format: :xml
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      context 'broker' do
        context 'in the agency' do
          before do
            initialize_and_login_broker[organization1]
            post :family_datatable, params: { id: bap_id }, xhr: true
            @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization1.profiles.first.id, organization1.profiles.first.market_kind)
          end

          it "should return a family" do
            expect(@query.total_count).not_to eq 0
          end

          it "should return success http status" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before do
            initialize_and_login_broker[organization2]
            post :family_datatable, params: { id: bap_id }, xhr: true
          end

          it "should not be a success" do
            expect(response.status).to_not have_http_status(:success)
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :show, params: { id: bap_id }
            @query = ::BenefitSponsors::Queries::BrokerFamiliesQuery.new(nil, organization1.profiles.first.id, organization1.profiles.first.market_kind)
          end

          it "should return a family" do
            expect(@query.total_count).not_to eq 0
          end

          it "should return success http status" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :show, params: { id: bap_id }
          end

          it "should not be a success" do
            expect(response.status).to_not have_http_status(:success)
          end
        end
      end
    end

    describe "#family_index" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the family_index template" do
            expect(response).to render_template("family_index")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end

          it "should not render the family_index template" do
            expect(response).to_not render_template("family_index")
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the family_index template" do
            expect(response).to render_template("family_index")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the family_index template" do
            expect(response).to_not render_template("family_index")
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the family_index template" do
            expect(response).to render_template("family_index")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :family_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the family_index template" do
            expect(response).to_not render_template("family_index")
          end
        end
      end
    end

    describe "#commission_statements" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the commission_statements template" do
            expect(response).to render_template("commission_statements")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end

          it "should not render the commission_statements template" do
            expect(response).to_not render_template("commission_statements")
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the commission_statements template" do
            expect(response).to render_template("commission_statements")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the commission_statements template" do
            expect(response).to_not render_template("commission_statements")
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the commission_statements template" do
            expect(response).to render_template("commission_statements")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :commission_statements, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the commission_statements template" do
            expect(response).to_not render_template("commission_statements")
          end
        end
      end
    end

    describe "#show_commission_statement" do
      let(:document) { broker_agency1.documents.create(title: 'TEST', identifier: '38470295384759384752') }

      before do
        s3_object = instance_double(Aws::S3Storage)
        allow(Aws::S3Storage).to receive(:find).with(document.identifier).and_return(s3_object)
      end

      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :show_commission_statement, params: { id: bap_id, statement_id: document.id }
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :show_commission_statement, params: {id: bap_id, statement_id: document.id}, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :show_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :show_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :show_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :show_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end
        end
      end
    end

    describe "#download_commission_statement" do
      let(:document) { broker_agency1.documents.create(title: 'TEST', identifier: '38470295384759384752') }

      before do
        s3_object = instance_double(Aws::S3Storage)
        allow(Aws::S3Storage).to receive(:find).with(document.identifier).and_return(s3_object)
      end

      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :download_commission_statement, params: { id: bap_id, statement_id: document.id }
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :download_commission_statement, params: {id: bap_id, statement_id: document.id}, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :download_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :download_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :download_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :download_commission_statement, params: { id: bap_id, statement_id: document.id }, xhr: true
          end

          it "should redirect to the broker agency profile page path" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end
        end
      end
    end

    describe "#general_agency_index" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the general_agency_index template" do
            expect(response).to render_template("general_agency_index")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end

          it "should not render the general_agency_index template" do
            expect(response).to_not render_template("general_agency_index")
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the general_agency_index template" do
            expect(response).to render_template("general_agency_index")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the general_agency_index template" do
            expect(response).to_not render_template("general_agency_index")
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the general_agency_index template" do
            expect(response).to render_template("general_agency_index")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :general_agency_index, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the general_agency_index template" do
            expect(response).to_not render_template("general_agency_index")
          end
        end
      end
    end

    describe "#messages" do
      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the messages template" do
            expect(response).to render_template("messages")
          end
        end

        context "with the incorrect permissions" do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          before :each do
            initialize_and_login_admin[dev_permission]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end

          it "should not render the messages template" do
            expect(response).to_not render_template("messages")
          end
        end
      end

      context "broker" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the messages template" do
            expect(response).to render_template("messages")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization2]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the messages template" do
            expect(response).to_not render_template("messages")
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the messages template" do
            expect(response).to render_template("messages")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :messages, params: { id: bap_id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency2.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the messages template" do
            expect(response).to_not render_template("messages")
          end
        end
      end
    end

    describe "#inbox" do
      # For the admin and broker_agency_staff tests, another broker needs to be created
      # this endpoint uses a primary_broker's id as the :id param, hence this before action

      let!(:person02) { FactoryBot.create(:person, :with_broker_role) }
      let!(:user_with_broker_role2) { FactoryBot.create(:user, person: person02) }

      before do
        person02.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: organization2.broker_agency_profile.id, aasm_state: 'active')
        allow(organization2.broker_agency_profile).to receive(:primary_broker_role).and_return(person02.broker_role)
        role = person02.create_broker_agency_staff_role({benefit_sponsors_broker_agency_profile_id: organization2.broker_agency_profile.id, aasm_state: 'active'})
        role.broker_agency_accept!
      end

      context "admin" do
        context "with the correct permissions" do
          before :each do
            initialize_and_login_admin[super_permission]
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the inbox template" do
            expect(response).to render_template("inbox")
          end
        end

        context "with the incorrect permissions" do
          before :each do
            initialize_and_login_admin[dev_permission]
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should redirect to new of registration's controller for broker_agency" do
            expect(response).to redirect_to(new_profiles_registration_path(profile_type: "broker_agency"))
          end

          it "should not render the inbox template" do
            expect(response).to_not render_template("inbox")
          end
        end

        context "with an invalid MIME type" do
          before :each do
            initialize_and_login_admin[super_permission]
          end

          it 'html returns a failure' do
            get :inbox, params: { id: person02.id }
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'json returns a failure' do
            get :inbox, params: { id: person02.id }, format: :json
            expect(response).to have_http_status(:not_acceptable)
          end

          it 'xml returns a failure' do
            get :inbox, params: { id: person02.id }, format: :xml
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      context "broker" do
        context 'in the agency' do

          before :each do
            sign_in(user_with_broker_role2)
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should render the inbox template" do
            expect(response).to render_template("inbox")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker[organization1]
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency1.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the inbox template" do
            expect(response).to_not render_template("inbox")
          end
        end
      end

      context "broker staff" do
        context 'in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization2]
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end

          it "should not render the inbox template" do
            expect(response).to render_template("inbox")
          end
        end

        context 'not in the agency' do
          before :each do
            initialize_and_login_broker_agency_staff[organization1]
            get :inbox, params: { id: person02.id }, xhr: true
          end

          it "should redirect to the profile page of their broker agency" do
            profile_page = profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency1.id)
            expect(response).to redirect_to(profile_page)
          end

          it "should not render the inbox template" do
            expect(response).to_not render_template("inbox")
          end
        end
      end
    end

    # this spec is testing a method for non-users to get emails about broker registration
    # no user-role related auth is required here, but may want to consider some kind of rate limit usage to prevent it from being abused
    describe "broker request registration guide" do
      before do
        post :email_guide, params: {email: 'Broker@test.com', first_name: 'Broker'}
      end

      it "should send Registration Guide to Broker@test.com" do
        expect(flash[:notice]).to eq "A copy of the Broker Registration Guide has been emailed to Broker@test.com"
      end
    end
  end
end
