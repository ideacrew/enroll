# frozen_string_literal: true

require 'rails_helper'

# Specs for testing BenefitSponsors::Profiles::RegistrationsController
module BenefitSponsors # rubocop:disable Metrics/ModuleLength
  RSpec.describe Profiles::RegistrationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let(:agency_class) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm }
    # let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc, :with_benefit_market) }
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item) }
    let(:person) { FactoryBot.create(:person) }
    let(:edit_user) { FactoryBot.create(:user, :person => person)}
    let(:user) { FactoryBot.create(:user) }
    let(:update_user) { edit_user }
    let(:benefit_sponsor_user) { user }
    let(:broker_agency_user) { nil }
    let(:general_agency_user) { nil }

    let(:phone_attributes) do
      {
        :kind => "work",
        :number => "8768776",
        :area_code => "876",
        :extension => "extension"
      }
    end

    let(:address_attributes) do
      {
        :kind => "primary",
        :address_1 => "address 1",
        :address_2 => "address 2",
        :city => "city",
        :state => "MA",
        :zip => "01026",
        :county => 'Berkshire'
      }
    end

    let(:office_locations_attributes) do
      {
        0 => {
          :is_primary => true,
          :address_attributes => address_attributes,
          :phone_attributes => phone_attributes
        }
      }
    end

    let(:employer_profile_attributes) do
      {
        :office_locations_attributes => office_locations_attributes,
        :contact_method => :paper_and_electronic
      }
    end

    let(:broker_profile_attributes) do
      { :ach_account_number => "1234567890",
        :ach_routing_number => "011000015",
        :ach_routing_number_confirmation => "011000015",
        :market_kind => :shop,
        :office_locations_attributes => office_locations_attributes,
        :contact_method => :paper_and_electronic}
    end

    let(:general_agency_profile_attributes) do
      {
        :market_kind => :shop,
        :office_locations_attributes => office_locations_attributes
      }
    end

    let(:benefit_sponsor_organization) do
      {
        :entity_kind => :tax_exempt_organization,
        :legal_name => "uweyrtuo",
        :dba => "uweyruoy",
        :fein => "111111111",
        :profile_attributes => employer_profile_attributes
      }
    end

    let(:broker_organization) do
      {
        :entity_kind => :s_corporation,
        :legal_name => "uweyrtuo",
        :dba => "uweyruoy",
        :fein => "222222222",
        :profile_attributes => broker_profile_attributes
      }
    end

    let(:general_agency_organization) do
      {
        :entity_kind => :s_corporation,
        :legal_name => "uweyrtuo",
        :dba => "uweyruoy",
        :fein => "333333333",
        :profile_attributes => general_agency_profile_attributes
      }
    end

    let(:staff_roles_attributes) do
      { 0 =>
        {
          :first_name => "weuryit",
          :last_name => "uyiwetr",
          :dob => "11/11/1990",
          :email => "t@t.com",
          :area_code => "786",
          :number => "8768766",
          :extension => "",
          :npn => "234234123"
        }}
    end

    let(:setting) { double }

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:general_agency).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_market).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:financial_assistance).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:redirect_to_requirements_page_after_confirmation).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_alphanumeric_npn).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:employer_attestation).and_return(true)
      # I couldn't get this to work, but since the default is :dc anyway, I'm leaving it here for now.
      # This spec should ultimately be refactored to remove any reference to a client in it
      # allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(setting)
      # allow(setting).to receive(:setting).with(:site_key).and_return(double(item: :dc))
      allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
    end

    shared_examples_for "initialize registration form" do |action, params, profile_type|
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:general_agency).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:employer_attestation).and_return(true)
        user = self.send("#{profile_type}_user")
        sign_in user if user
        if params[:id].present?
          sign_in edit_user
          params[:id] = self.send(profile_type).profiles.first.id.to_s
        end

        params[:agency] = self.send("#{profile_type}_params") if params.empty?
        get action, params: params
      end
      it "should initialize agency" do
        expect(assigns(:agency).class).to eq agency_class
      end

      it "should have #{profile_type} as profile type on form" do
        expect(assigns(:agency).profile_type).to eq(params[:profile_type] || profile_type)
      end
    end

    describe "GET new", dbclean: :after_each do

      shared_examples_for "initialize profile for new" do |profile_type|

        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:general_agency).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:employer_attestation).and_return(true)
          user = self.send("#{profile_type}_user")
          sign_in user if user
          get :new, params: {profile_type: profile_type}
        end

        it "should render new template" do
          expect(response).to render_template("new")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      it_behaves_like "initialize profile for new", "benefit_sponsor"
      it_behaves_like "initialize profile for new", "broker_agency"
      it_behaves_like "initialize profile for new", "general_agency"
      # it_behaves_like "initialize profile for new", "issuer"
      # it_behaves_like "initialize profile for new", "contact_center"
      # it_behaves_like "initialize profile for new", "fedhb"

      it_behaves_like "initialize registration form", :new, {profile_type: "benefit_sponsor"}, "benefit_sponsor"
      it_behaves_like "initialize registration form", :new, {profile_type: "broker_agency"}, "broker_agency"
      it_behaves_like "initialize registration form", :new, { profile_type: "general_agency" }, "general_agency"
      # it_behaves_like "initialize registration form", :new, { profile_type: "issuer" }
      # it_behaves_like "initialize registration form, :new, { profile_type:  "contact_center" }
      # it_behaves_like "initialize registration form", :new, { profile_type: "fedhb" }

      describe "profile_type params" do
        context "random class passed as profile_type" do
          context "not signed in"
          before do
            get :new, params: { profile_type: "Thishouldnotexistandhopefullyitwillnot", portal: true }
          end

          it "should not throw an exception" do
            expect(response).to redirect_to('http://test.host/users/sign_in')
            expect(assigns(:agency).portal).to eq(true)
          end
        end
        context "signed in" do
          before do
            sign_in user
            get :new, params: { profile_type: "Thishouldnotexistandhopefullyitwillnot", portal: true }
          end

          it "should not throw an exception and render new template" do
            expect(response).to render_template :new
            expect(assigns(:agency).portal).to eq(true)
          end
        end
      end

      describe "for new on broker_agency_portal", dbclean: :after_each do
        context "for new on broker_agency_portal click without user" do

          before :each do
            allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:general_agency).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:employer_attestation).and_return(true)
            get :new, params: {profile_type: "broker_agency", portal: true}
          end

          it "should redirect to sign_up page if current user doesn't exist" do
            expect(response.location.include?("users/sign_in")).to eq true
          end

          it "should set the value of portal on form instance to true" do
            expect(assigns(:agency).portal).to eq true
          end
        end

        context "for new on broker_agency_portal click without user" do
          let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
          let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
          let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
          let(:broker_agency_id) { broker_agency_organization.broker_agency_profile.id }

          before :each do
            allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
            broker_person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            sign_in broker_user
            get :new, params: {profile_type: "broker_agency", portal: true}
          end

          it "should redirect to show page if current user exists and passes the pundit" do
            expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency_id))
          end

          it "should set the value of portal on form instance to true" do
            expect(assigns(:agency).portal).to eq true
          end
        end
      end
    end

    describe "POST create", dbclean: :after_each do

      context "creating profile" do

        let(:benefit_sponsor_params) do
          {
            :profile_type => "benefit_sponsor",
            :staff_roles_attributes => staff_roles_attributes,
            :organization => benefit_sponsor_organization
          }
        end

        let(:broker_agency_params) do
          {
            :profile_type => "broker_agency",
            :staff_roles_attributes => staff_roles_attributes,
            :organization => broker_organization
          }
        end

        let(:general_agency_params) do
          {
            :profile_type => "general_agency",
            :staff_roles_attributes => staff_roles_attributes,
            :organization => general_agency_organization
          }
        end

        context 'with valid params' do
          before :each do
            allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:employer_attestation).and_return(true)
            # allow(EnrollRegistry).to receive(:feature_enabled?).with(:redirect_to_requirements_page_after_confirmation).and_return(true)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(false)
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_approval_period).and_return(true)
            site.benefit_markets.first.save!
            # Stubbing the controller method (which has two conditions, one of which is a Resource Registry check) is easier
            allow(controller).to receive(:verify_recaptcha_if_needed).and_return(true)
          end

          shared_examples_for "store profile for create" do |profile_type|
            before :each do
              allow(EnrollRegistry).to receive(:feature_enabled?).with(:general_agency).and_return(true) if profile_type == 'general_agency'
              BenefitSponsors::Organizations::BrokerAgencyProfile::MARKET_KINDS << :shop if profile_type == 'broker_agency'
              BenefitSponsors::Organizations::GeneralAgencyProfile::MARKET_KINDS << :shop if profile_type == 'general_agency'
              allow(controller).to receive(:is_broker_profile?).and_return(true) if profile_type == 'broker_agency'
              allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_alphanumeric_npn).and_return(false) if profile_type == 'broker_agency'
              allow(controller).to receive(:redirect_to_requirements_after_confirmation?).and_return(true) if profile_type == 'broker_agency'

              user = self.send("#{profile_type}_user")
              sign_in user if user
              post :create, params: {:agency => self.send("#{profile_type}_params")}
            end

            it "should redirect for benefit_sponsor and general agency" do
              expect(response).to have_http_status(:redirect) if profile_type != 'broker_agency'
            end

            it "should render confirmation template for broker agency" do
              expect(response).to render_template('confirmation') if profile_type == 'broker_agency'
            end

            it "should redirect to home page of benefit_sponsor" do
              expect(response.location.include?("tab=home")).to eq true if profile_type == "benefit_sponsor"
            end

            it "should redirect to new for general agency" do
              expect(response.location.include?("new?profile_type=general_agency")).to eq true if profile_type == "general_agency"
            end

            it "should create staff person with no ssn" do
              person = Person.where(
                first_name: staff_roles_attributes[0][:first_name],
                last_name: staff_roles_attributes[0][:last_name],
                dob: staff_roles_attributes[0][:dob]
              ).first
              expect("1").to eq person.no_ssn
            end
          end

          it_behaves_like "store profile for create", "benefit_sponsor"
          it_behaves_like "store profile for create", "broker_agency"
          it_behaves_like "store profile for create", "general_agency"

          it_behaves_like "initialize registration form", :create, {}, "benefit_sponsor"
          it_behaves_like "initialize registration form", :create, {}, "broker_agency"
          it_behaves_like "initialize registration form", :create, {}, "general_agency"

          context 'requests with correct params but valid/invalid format' do
            before :each do
              BenefitSponsors::Organizations::BrokerAgencyProfile::MARKET_KINDS << :shop
              allow(controller).to receive(:is_broker_profile?).and_return(true)
              allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_alphanumeric_npn).and_return(false)
              allow(controller).to receive(:redirect_to_requirements_after_confirmation?).and_return(true)

              user = self.send("broker_agency_user")
              sign_in user if user
            end

            it "should return a success" do
              post :create, params: {:agency => self.send("broker_agency_params")}
              expect(response.status).to eq(200)
              expect(response).to render_template('confirmation')
            end

            it "should not render the confirmation template" do
              post :create, params: {:agency => self.send("broker_agency_params")}, format: :js
              expect(response).to have_http_status(:not_acceptable)
            end

            it "should not return a success" do
              post :create, params: {:agency => self.send("broker_agency_params")}, format: :json
              expect(response).to have_http_status(:not_acceptable)
            end

            it "should not return a success" do
              post :create, params: {:agency => self.send("broker_agency_params")}, format: :xml
              expect(response).to have_http_status(:not_acceptable)
            end
          end
        end

        shared_examples_for "fail store profile for create if params invalid" do |profile_type|

          before do
            sign_in user
            address_attributes.merge!({
                                        kind: nil
                                      })
            post :create, params: {:agency => self.send("#{profile_type}_params")}
          end

          it "should success" do
            expect(response).to have_http_status(:success)
          end

          it "should render new" do
            expect(response).to render_template :new
          end

          it "should have profile_type in params" do
            expect(controller.params[:agency][:profile_type] == "benefit_sponsor").to eq true if profile_type == "benefit_sponsor"
            expect(controller.params[:agency][:profile_type] == "broker_agency").to eq true if profile_type == "broker_agency"
            expect(controller.params[:agency][:profile_type] == "general_agency").to eq true if profile_type == "general_agency"
          end
        end

        it_behaves_like "fail store profile for create if params invalid", "benefit_sponsor"
        it_behaves_like "fail store profile for create if params invalid", "broker_agency"
        it_behaves_like "fail store profile for create if params invalid", "general_agency"
      end

      context "with invalid captcha" do
        let(:general_agency_params) do
          {
            profile_type: "general_agency",
            staff_roles_attributes: staff_roles_attributes,
            organization: general_agency_organization
          }
        end

        it "does not redirect" do
          allow(controller).to receive(:verify_recaptcha_if_needed).and_return(false)
          post :create, params: { agency: general_agency_params }

          expect(response).to render_template :new
        end
      end
    end

    describe "GET edit", dbclean: :after_each do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
      end

      let!(:benefit_sponsor) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:benefit_sponsorship) do
        benefit_sponsorship = benefit_sponsor.profiles.first.add_benefit_sponsorship
        benefit_sponsorship.save
      end
      let(:broker_agency)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
      let!(:staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: benefit_sponsor.profiles.first.id)}
      let!(:employer_staff_roles) { person.employer_staff_roles << staff_role }
      let!(:broker_role) {FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency.profiles.first.id,person: person)}
      let!(:update_profile) { broker_agency.profiles.first.update_attributes(primary_broker_role_id: broker_role.id)}

      let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency.profiles.first.id, person: person, aasm_state: 'active', is_primary: true)}

      shared_examples_for "initialize profile for edit" do |profile_type|

        before do
          sign_in edit_user
          @id = self.send(profile_type).profiles.first.id.to_s
          get :edit, params: {id: @id}
        end

        it "should render edit template" do
          expect(response).to render_template("edit")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end

        it "should initialize agency" do
          expect(assigns(:agency).class).to eq agency_class
        end

        it "should have #{profile_type} as profile type on form" do
          expect(assigns(:agency).profile_type).to eq profile_type
        end

        it "should have nil as profile id on form" do
          expect(assigns(:agency).profile_id).to eq @id
        end
      end

      it_behaves_like "initialize profile for edit", "benefit_sponsor"
      it_behaves_like "initialize profile for edit", "broker_agency"
      it_behaves_like "initialize profile for edit", "general_agency"

      it_behaves_like "initialize registration form", :edit, { id: "id"}, "benefit_sponsor"
      it_behaves_like "initialize registration form", :edit, { id: "id" }, "broker_agency"
      it_behaves_like "initialize registration form", :edit, { id: "id" }, "general_agency"

      context 'with valid params but valid/invalid format' do
        before do
          sign_in edit_user
          @id = self.send('broker_agency').profiles.first.id.to_s
        end

        it "html should return a success" do
          get :edit, params: {id: @id}
          expect(response).to have_http_status(:success)
          expect(response).to render_template('edit')
        end

        it "js should raise an error" do
          expect do
            (get :edit, params: {id: @id}, format: :js).to raise_error(ActionView::MissingTemplate)
          end
        end

        it "json should raise an error" do
          expect do
            (get :edit, params: {id: @id}, format: :json).to raise_error(ActionView::MissingTemplate)
          end
        end

        it "xml should raise an error" do
          expect do
            (get :edit, params: {id: @id}, format: :xml).to raise_error(ActionView::MissingTemplate)
          end
        end
      end
    end

    describe "PUT update", dbclean: :after_each do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_edit_broker_npn).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_edit_broker_email).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
      end

      context "updating profile" do

        let(:person) { FactoryBot.create :person}

        let(:benefit_sponsor) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:broker_agency)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }

        let(:benefit_sponsor_params) do
          {
            :id => benefit_sponsor.profiles.first.id,
            :staff_roles_attributes => staff_roles_attributes,
            :organization => benefit_sponsor_organization
          }
        end

        let(:broker_agency_params) do
          {
            :id => broker_agency.profiles.first.id,
            :staff_roles_attributes => staff_roles_attributes,
            :organization => broker_organization
          }
        end

        let(:general_agency_params) do
          {
            :id => general_agency.profiles.first.id,
            :staff_roles_attributes => staff_roles_attributes,
            :organization => general_agency_organization
          }
        end

        def sanitize_attributes(profile_type)
          employer_profile_attributes.merge!({
                                               id: self.send(profile_type).profiles.first.id.to_s
                                             })

          broker_profile_attributes.merge!({
                                             id: self.send(profile_type).profiles.first.id.to_s
                                           })

          general_agency_profile_attributes.merge!({
                                                     id: self.send(profile_type).profiles.first.id.to_s
                                                   })

          staff_roles_attributes[0].merge!({
                                             person_id: person.id
                                           })
        end

        shared_examples_for "store profile for update" do |profile_type|

          before :each do
            sanitize_attributes(profile_type)
            sign_in update_user
            put :update, params: {:agency => self.send("#{profile_type}_params"), :id => self.send("#{profile_type}_params")[:id]}
          end

          it "should initialize agency" do
            expect(assigns(:agency).class).to eq agency_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should redirect to edit for benefit_sponsor" do
            expect(response.location.include?("/edit")).to eq true if profile_type == "benefit_sponsor"
          end

          it "should redirect to show for broker_agency or general agency" do
            expect(response.location.include?("/broker_agency_profiles/")).to eq true if profile_type == "broker_agency"
            expect(response.location.include?("/general_agency_profiles/")).to eq true if profile_type == "general_agency"
          end
        end

        it_behaves_like "store profile for update", "benefit_sponsor"
        it_behaves_like "store profile for update", "broker_agency"
        it_behaves_like "store profile for update", "general_agency"
        # it_behaves_like "store profile for update", "issuer"
        # it_behaves_like "store profile for update", "contact_center"
        # it_behaves_like "store profile for update", "fedhb"

        shared_examples_for "fail store profile for update if params invalid" do |profile_type|

          before do
            sign_in update_user
            sanitize_attributes(profile_type)
            address_attributes.merge!({
                                        kind: nil
                                      })
            put :update, params: {:agency => self.send("#{profile_type}_params"), :id => self.send("#{profile_type}_params")[:id]}
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should redirect to new" do
            expect(response.location.include?("/edit")).to eq true
          end
        end

        it_behaves_like "fail store profile for update if params invalid", "benefit_sponsor"
        it_behaves_like "fail store profile for update if params invalid", "broker_agency"
        it_behaves_like "fail store profile for update if params invalid", "general_agency"
        # it_behaves_like "fail store profile for update if params invalid", "issuer"
        # it_behaves_like "fail store profile for update if params invalid", "contact_center"
        # it_behaves_like "fail store profile for update if params invalid", "fedhb"
      end
    end

    describe "GET counties_for_zip_code" do
      context 'valid params with valid/invalid formats' do
        before do
          sign_in edit_user
        end

        it "html should return a success" do
          get :counties_for_zip_code, params: {zip_code: address_attributes[:zip]}
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should return a success" do
          get :counties_for_zip_code, params: {zip_code: address_attributes[:zip]}, format: :json
          expect(response).to have_http_status(:success)
        end

        it "js should return an error" do
          get :counties_for_zip_code, params: {zip_code: address_attributes[:zip]}, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should return an error" do
          get :counties_for_zip_code, params: {zip_code: address_attributes[:zip]}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end
  end
end
