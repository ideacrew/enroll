# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  after :all do
    DatabaseCleaner.clean
  end

  let(:person1) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person1) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }
  let!(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
    person1.ensure_relationship_with(per, 'spouse')
    person1.save!
    per
  end
  let!(:family_member_2) { FactoryBot.create(:family_member, person: person2, family: family)}
  let!(:person3) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years)
    person1.ensure_relationship_with(per, 'child')
    person1.save!
    per
  end
  let!(:family_member_3) { FactoryBot.create(:family_member, person: person3, family: family)}
  let!(:person4) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years)
    person1.ensure_relationship_with(per, 'child')
    person1.save!
    per
  end
  let!(:family_member_4) { FactoryBot.create(:family_member, person: person4, family: family)}

  let(:family_id) { family.id}
  let(:effective_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:application_period) {effective_on.beginning_of_year..effective_on.end_of_year}

  before do
    family.primary_person.consumer_role.move_identity_documents_to_verified
  end

  describe "GET index" do
    before(:each) do
      sign_in user
    end

    it "assigns @applications" do
      application = FinancialAssistance::Application.create!(family_id: family_id)
      get :index
      expect(assigns(:applications).to_a).to eq([application])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end

    context "when the request type is invalid" do
      it "renders the index template" do
        get :index, format: :json
        expect(response.status).to eq 406
        expect(response.body).to eq "{\"error\":\"Unsupported format\"}"
        expect(response.media_type).to eq "application/json"
      end

      it "renders the index template" do
        get :index, format: :fake
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "renders the index template" do
        get :index, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end

    context 'for a person who exists in multiple families(with financial assistance applications)' do
      let!(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }
      let!(:application1) { FinancialAssistance::Application.create!(family_id: family_id) }
      let!(:application2) { FinancialAssistance::Application.create!(family_id: family2.id) }
      let!(:family_member_2_2) { FactoryBot.create(:family_member, person: person1, family: family2)}

      before do
        get :index
      end

      it 'should include applications associated with family1' do
        expect(assigns(:applications).map(&:id).map(&:to_s)).to include(application1.id.to_s)
      end

      it 'should NOT include applications associated with family2' do
        expect(assigns(:applications).map(&:id).map(&:to_s)).not_to include(application2.id.to_s)
      end
    end
  end

  context "copy an application" do
    let(:family1_id) { family.id }
    let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family.id, aasm_state: 'determined' }
    let(:current_hbx_profile) { OpenStruct.new(under_open_enrollment?: true) }

    before(:each) do
      sign_in user
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_profile)
      applicants = application.applicants
      application.add_or_update_relationships(applicants[0], applicants[1], 'spouse')
      application.add_or_update_relationships(applicants[0], applicants[2], 'parent')
      application.add_or_update_relationships(applicants[0], applicants[3], 'parent')
      application.add_or_update_relationships(applicants[1], applicants[2], 'parent')
      application.add_or_update_relationships(applicants[1], applicants[3], 'parent')
      application.add_or_update_relationships(applicants[2], applicants[3], 'sibling')
      application.relationships << ::FinancialAssistance::Relationship.new(kind: 'spouse', applicant_id: applicants[0].id, relative_id: applicants[1].id)
      application.relationships << ::FinancialAssistance::Relationship.new(kind: 'spouse', applicant_id: applicants[0].id, relative_id: applicants[1].id)
    end

    context 'when application service raises an error' do

      before do
        get :copy, params: { :id => application.id }
        @new_application = FinancialAssistance::Application.where(family_id: application.family_id, :id.ne => application.id).first
      end

      it "redirects to the new application copy" do
        expect(response).to redirect_to(edit_application_path(assigns(:application).reload))
      end

      it 'create duplicate application' do
        expect(@new_application.family_id).to eq application.family_id
      end

      it 'create duplicate application with assistance year' do
        expect(@new_application.assistance_year).not_to eq nil
      end

      it 'copies all the applicants' do
        expect(@new_application.applicants.count).to eq application.applicants.count
      end

      it 'does not copy duplicate relationships' do
        applicants = @new_application.applicants
        expect(@new_application.relationships.where(applicant_id: applicants[0].id, relative_id: applicants[1].id).count).to eq 1
      end

      it 'only copies relationships to the primary applicant' do
        applicants = @new_application.applicants
        expect(@new_application.relationships.where(applicant_id: applicants[2].id, relative_id: applicants[3].id).count).to eq 0
        expect(@new_application.relationships.count).to eq 6
      end
    end
  end
end

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  routes { FinancialAssistance::Engine.routes }
  let(:event) { Success(double) }
  let(:obj)  { FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: 1234)}
  let(:hbx_staff_role) { double("hbx_staff_role")}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}
  let(:family_member_id) { family.primary_applicant.id }
  let!(:application) { FactoryBot.create(:application, hbx_id: 1234, assistance_year: Date.today.year, created_at: Date.today - 1.day, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  person_hbx_id: 1234,
                                  family_member_id: family_member_id,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application,
                                  ethnicity: [],
                                  is_self_attested_blind: false,
                                  is_primary_applicant: true,
                                  is_applying_coverage: true,
                                  is_required_to_file_taxes: true,
                                  is_pregnant: false,
                                  has_job_income: false,
                                  has_self_employment_income: false,
                                  has_unemployment_income: false,
                                  has_other_income: false,
                                  has_deductions: false,
                                  has_daily_living_help: false,
                                  need_help_paying_bills: false,
                                  has_enrolled_health_coverage: false,
                                  has_eligible_health_coverage: false,
                                  has_eligible_medicaid_cubcare: false,
                                  is_claimed_as_tax_dependent: false,
                                  is_incarcerated: false,
                                  is_post_partum_period: false,
                                  citizen_status: 'us_citizen')
    applicant
  end
  let!(:application2) { FactoryBot.create(:application, hbx_id: 3456, assistance_year: Date.today.year + 1, created_at: Date.today + 1.day, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
  let!(:applicant2) { FactoryBot.create(:applicant, application: application2,  family_member_id: family_member_id) }
  let(:application_valid_params) { {"medicaid_terms" => "yes", "report_change_terms" => "yes", "medicaid_insurance_collection_terms" => "yes", "parent_living_out_of_home_terms" => "true", "attestation_terms" => "yes", "submission_terms" => "yes"} }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period)}
  let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person, oim_id: '1234567899', email: 'test@test.com') }

  #set of objects that doesnt belong to the first family/user to validate the records returned only belong to the user logged in
  let(:person10) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user2) { FactoryBot.create(:user, :person => person10, oim_id: '7734567899',email: "thisshouldnot@behappening.com") }
  let!(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
  let!(:person20) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
    person10.ensure_relationship_with(per, 'spouse')
    person10.save!
    per
  end
  let!(:family_member_20) { FactoryBot.create(:family_member, person: person20, family: family2)}
  let!(:person30) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years)
    person10.ensure_relationship_with(per, 'child')
    person10.save!
    per
  end
  let!(:family_member_30) { FactoryBot.create(:family_member, person: person30, family: family2)}
  let!(:person40) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years)
    person10.ensure_relationship_with(per, 'child')
    person10.save!
    per
  end
  let!(:family_member_40) { FactoryBot.create(:family_member, person: person40, family: family2)}
  let(:family_id2) { family2.id}
  let(:application20) { FactoryBot.create(:application, family: family2, aasm_state: "draft", effective_on: effective_on, application_period: application_period)}

  before do
    allow(person).to receive(:financial_assistance_identifier).and_return(family_id)
    sign_in(user)
    family.primary_person.consumer_role.move_identity_documents_to_verified
  end

  describe '#index' do
    context 'primary person is RIDP verified' do
      it 'assigns applications' do
        get :index
        applications = FinancialAssistance::Application.where(family_id: family_id)
        expect(assigns(:applications)).to match_array(applications.to_a)
      end
    end

    context 'primary person is not RIDP verified' do
      it 'redirects to root_path with a flash message' do
        family.primary_person.consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
        get :index
        expect(response).to redirect_to(main_app.root_path)
        expect(flash[:error]).to eq('Access not allowed for family_policy.index?, (Pundit policy)')
      end
    end
  end

  describe "GET edit" do
    context "With valid data" do
      it "should render" do
        get :edit, params: { id: application.id }
        expect(assigns(:application)).to eq application
        expect(response).to render_template(:financial_assistance_nav)
      end
    end

    context "when the request type is invalid" do
      it "should not render the raw_application template" do
        get :edit, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the raw_application template" do
        get :edit, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the raw_application template" do
        get :edit, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end

    context "With missing family id" do
      it "should find the correct application" do
        sign_in(admin_user)
        get :edit, params: { id: application.id }, session: { person_id: application.family.primary_person.id }
        expect(assigns(:application)).to eq application
      end
    end

    context 'broker logged in' do
      let!(:broker_user) { FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role']) }
      let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile, market_kind: :both) }
      let(:writing_agent) do
        FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: "active")
      end
      let(:assister)  do
        assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00", aasm_state: "active")
        assister.save(validate: false)
        assister
      end
      let(:user) { broker_user }

      before { family.primary_person.consumer_role.move_identity_documents_to_verified }

      context 'hired by family' do
        before(:each) do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              writing_agent_id: writing_agent.id,
                                                                                              start_on: Time.now,
                                                                                              is_active: true)

          family.reload
        end

        it "should render" do
          get :edit, params: { id: application.id }, session: { person_id: family.primary_person.id }
          expect(assigns(:application)).to eq application
          expect(response).to render_template(:financial_assistance_nav)
        end
      end

      context 'not hired by family' do
        it "should render" do
          get :edit, params: { id: application.id }, session: { person_id: family.primary_person.id }
          expect(assigns(:application)).to eq application
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq('Access not allowed for financial_assistance/application_policy.edit?, (Pundit policy)')
        end
      end
    end
  end

  context "POST save_preferences" do
    before do
      allow(controller).to receive(:haven_determination_is_enabled?).and_return(true)
      setup_faa_data
      allow(FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
      allow(obj).to receive(:build_event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
      controller.instance_variable_set(:@model, application.reload)
    end

    it "shows errors when @application does not save" do
      allow(application).to receive_message_chain('errors.full_messages').and_return(
        ["Hbx id can't be blank", "fake errors can't be blank"]
      )
      allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
      allow(application).to receive(:save).and_return(false)
      allow(application).to receive(:save!).with(validate: false).and_return(false)
      allow(application).to receive(:valid?).and_return(false)
      post :save_preferences, params: {application: application.attributes, id: application.id }
      expect(flash[:error]).to eq("Hbx id can't be blank, fake errors can't be blank")
    end

    it "shows errors when @model does not save and errors blank" do
      # to give errors
      allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
      allow(application).to receive(:save).and_return(false)
      allow(application).to receive(:save!).with(validate: false).and_return(false)
      allow(application).to receive(:valid?).and_return(false)
      post :save_preferences, params: {application: application.attributes, id: application.id }
      expect(flash[:error]).to eq("")
    end

    it "should render preferences if model is not saved" do
      post :save_preferences, params: { id: application.id }
      expect(response).to render_template 'preferences'
    end

    it "should redirect to the submit your application page if successful" do
      post :save_preferences, params: { id: application.id, application: application_valid_params }
      expect(response).to redirect_to(submit_your_application_application_path(application))
    end
  end

  context "POST submit" do
    before do
      allow(controller).to receive(:haven_determination_is_enabled?).and_return(true)
      setup_faa_data
      allow(FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
      allow(obj).to receive(:build_event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
      controller.instance_variable_set(:@model, application.reload)
    end

    context "submit step with a valid but incomplete application" do
      before do
        application.update_attributes!(aasm_state: 'draft')
        allow(application).to receive(:complete?).and_return(false)
        allow(application).to receive(:save).and_return(true)
        allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
        allow(controller).to receive(:build_error_messages)

        post :submit, params: { id: application.id, application: application_valid_params }
      end

      it "should render error page when there is an incomplete or already submitted application" do
        expect(response).to redirect_to(application_publish_error_application_path(application))
      end
    end

    context "submit with a publish_result failure" do
      # receive_message_chain(:new, :call).and_return(success_result)
      let(:operation) { double new: double(call: double(failure: failure, success?: false)) }

      before do
        application.update_attributes!(aasm_state: 'submitted')
        allow(application).to receive(:complete?).and_return(true)
        allow(application).to receive(:may_submit?).and_return(true)
        allow(application).to receive(:submit!).and_return(true)
        allow(application).to receive(:save).and_return(true)
        allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
        allow(controller).to receive(:determination_request_class).and_return(operation)

        post :submit, params: { id: application.id, application: application_valid_params }
      end

      context "containing a failed Dry::Validation::Result" do
        let(:failure) do
          Dry::Validation::Result.new(double(message_set: [], to_h: {})) do |r|
            r.add_error(Dry::Validation::Message.new("length must be within 10 - 15",
                                                     path: [:applicants, 0, :phones, 0, :full_phone_number]))
          end
        end

        it 'redirects to application_publish_error_application_path' do
          expect(response).to redirect_to(application_publish_error_application_path(application.id))
        end

        it 'builds the flash message correctly' do
          expect(flash[:error].first).to eql("The 1st applicants's 1st phones's full phone number: length must be within 10 - 15.")
        end
      end

      context "containing an Exception" do
        let(:failure) do
          StandardError.new("test")
        end

        it 'builds the flash message with the exception text' do
          expect(flash[:error]).to eql('test')
        end
      end

      context "containing with a string" do
        let(:failure) { "big big problem" }

        it 'builds the flash message with the string' do
          expect(flash[:error]).to eql('Submission Error: big big problem')
        end
      end
    end
    context "when params has application key" do
      let(:success_result) { double(success?: true)}

      let!(:create_home_address) do
        [application, application2].each do |applin|
          applin.applicants.first.update_attributes!(is_primary_applicant: true)
          address_attributes = {
            kind: 'home',
            address_1: '3 Awesome Street',
            address_2: '#300',
            city: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_city).item,
            state: FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
            zip: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_zip_code).item
          }
          if EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item == 'county'
            address_attributes.merge!(
              county: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_county).item
            )
          end
          financial_assistance_address = ::FinancialAssistance::Locations::Address.new(address_attributes)
          applin.reload
          applin.applicants.each do |applicant|
            applicant.addresses << financial_assistance_address
            applicant.save!
          end
          family_id = applin.family_id
          family = Family.find(family_id) if family_id.present?
          next unless family
          family.family_members.each do |fm|
            main_app_address = Address.new(address_attributes)
            fm.person.addresses << main_app_address
            fm.person.save!
          end
        end
      end

      before do
        applicant1 = application2.applicants.first
        applicant2 = application2.applicants.last
        application2.add_or_update_relationships(applicant1, applicant2, "spouse")
      end

      it "When model is saved" do
        post :submit, params: { id: application.id, application: application_valid_params }
        expect(application.save).to eq true
      end

      context "when the request type is invalid" do
        it "should be an error when csv" do
          post :submit, params: { id: application.id, application: application_valid_params }, format: :csv
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
          expect(response.media_type).to eq "text/csv"
        end

        it "should be an error when js" do
          post :submit, params: { id: application.id, application: application_valid_params }, format: :js
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
        end

        it "should be an error when xml" do
          post :submit, params: { id: application.id, application: application_valid_params }, format: :xml
          expect(response.status).to eq 406
          expect(response.body).to eq "<error>Unsupported format</error>"
        end
      end

      it "should fail during publish application and redirects to error_page" do
        application2.ensure_relationship_with_primary(application2.applicants[1], 'spouse')
        post :submit, params: { id: application2.id, application: application_valid_params }
        expect(flash[:error]).to match(/Submission Error: /)
        expect(response).to redirect_to(application_publish_error_application_path(application2))
      end

      it "should successfully publish application and redirects to wait_for_eligibility" do
        application.update_attributes!(aasm_state: 'submitted')
        application.reload
        allow(application).to receive(:complete?).and_return(true)
        allow(application).to receive(:may_submit?).and_return(true)
        allow(application).to receive(:submit!).and_return(true)
        allow(FinancialAssistance::Operations::Application::RequestDetermination).to receive_message_chain(:new, :call).and_return(success_result)
        allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
        post :submit, params: { id: application.id, application: application_valid_params }
        expect(response).to redirect_to(wait_for_eligibility_response_application_path(application))
      end
    end

    it "should re if model is not saved" do
      post :submit, params: { id: application.id }
      expect(response).to render_template 'financial_assistance/applications/submit_your_application'
    end
  end

  context "GET copy" do
    context "when there is not response from eligibility service" do
      let(:current_hbx_profile) { OpenStruct.new(under_open_enrollment?: true) }

      before do
        FinancialAssistance::Application.where(family_id: family_id).each {|app| app.update_attributes(aasm_state: "determined")}
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_profile)
      end

      it 'should copy applicant and redirect to financial assistance application edit path unless iap_year_selection enabled' do
        skip "skipped: iap_year_selection enabled" if FinancialAssistanceRegistry[:iap_year_selection].enabled?

        get :copy, params: { id: application.id }
        existing_app_ids = [application.id, application2.id]
        copy_app = FinancialAssistance::Application.where(family_id: family_id).reject {|app| existing_app_ids.include? app.id}.first
        expect(response).to redirect_to(edit_application_path(copy_app.id))
      end

      it 'should copy applicant and redirect to financial assistance assistance year select path if iap_year_selection enabled' do
        skip "skipped: iap_year_selection not enabled" unless FinancialAssistanceRegistry[:iap_year_selection].enabled?

        get :copy, params: { id: application.id }
        existing_app_ids = [application.id, application2.id]
        copy_app = FinancialAssistance::Application.where(family_id: family_id).reject {|app| existing_app_ids.include? app.id}.first
        expect(response).to redirect_to(application_year_selection_application_path(copy_app.id))
      end
    end

    context "when there is response from eligibility service" do
      include FinancialAssistance::L10nHelper
      include ActionView::Helpers::TranslationHelper

      before do
        allow(controller).to receive(:call_service)
        controller.instance_variable_set(:@assistance_status, false)
        controller.instance_variable_set(:@message, "101")
        get :copy, params: { id: application.id }
      end

      let(:message) {l10n("faa.acdes_lookup")}

      it 'should not copy applicant and redirect to financial_assistance_applications_path' do
        expect(response).to redirect_to(applications_path)
      end

      it 'should not copy applicant and throw message' do
        expect(flash[:error].to_s).to match(message)
      end
    end

    context 'broker logged in' do
      let!(:broker_user) { FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role']) }
      let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile, market_kind: :both) }

      let(:writing_agent) do
        FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: "active")
      end

      let(:assister)  do
        assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00", aasm_state: "active")
        assister.save(validate: false)
        assister
      end
      let(:user) { broker_user }
      let(:current_hbx_profile) { OpenStruct.new(under_open_enrollment?: true) }

      before do
        FinancialAssistance::Application.where(family_id: family_id).each {|app| app.update_attributes(aasm_state: "determined")}
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_profile)
        family.primary_person.consumer_role.move_identity_documents_to_verified
      end

      context 'hired by family' do
        before(:each) do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              writing_agent_id: writing_agent.id,
                                                                                              start_on: Time.now,
                                                                                              is_active: true)
          family.reload
        end

        it "should render" do
          skip "skipped: iap_year_selection enabled" if FinancialAssistanceRegistry[:iap_year_selection].enabled?

          get :copy, params: { id: application.id }, session: { person_id: family.primary_person.id }
          existing_app_ids = [application.id, application2.id]
          copy_app = FinancialAssistance::Application.where(family_id: family_id).reject {|app| existing_app_ids.include? app.id}.first
          expect(response).to redirect_to(edit_application_path(copy_app.id))
        end
      end

      context 'not hired by family' do
        it "should render" do
          skip "skipped: iap_year_selection enabled" if FinancialAssistanceRegistry[:iap_year_selection].enabled?

          get :copy, params: { id: application.id }, session: { person_id: family.primary_person.id }
          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq('Access not allowed for financial_assistance/application_policy.copy?, (Pundit policy)')
        end
      end
    end
  end

  context "GET review_and_submit" do
    it 'should review and submit page' do
      application.update_attributes(:aasm_state => "draft")
      get :review_and_submit, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(assigns(:application).aasm_state).to eq("draft")
      expect(response).to render_template(:financial_assistance_nav)
    end

    context "when the request type is invalid" do
      before do
        application.update_attributes(:aasm_state => "draft")
      end

      it "should not render the review_and_submit template" do
        get :review_and_submit, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the review_and_submit template" do
        get :review_and_submit, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the review_and_submit template" do
        get :review_and_submit, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end

    context 'when the application does not have valid relations' do
      before do
        allow_any_instance_of(FinancialAssistance::Application).to receive(:valid_relations?).and_return(false)
      end

      it 'should throw and redirect to relationship page' do
        application.update_attributes(:aasm_state => "draft")
        get :review_and_submit, params: { id: application.id }
        expect(response).to redirect_to(application_relationships_path(application))
      end
    end
  end

  context "GET review" do
    before do
      sign_in(user)
    end

    it "should be successful" do
      application.update_attributes(:aasm_state => "submitted")
      get :review, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end

    it "should redirect to applications page" do
      get :review, params: { id: FinancialAssistance::Application.new.id }
      expect(response).to redirect_to(applications_path)
    end

    context "when the request type is invalid" do
      before do
        application.update_attributes(:aasm_state => "submitted")
      end

      it "should not render the review template" do
        get :review, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the review template" do
        get :review, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the review template" do
        get :review, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end
  end

  context "GET raw" do
    let(:temp_file) do
      [{"demographics" => {} },
       {"financial_assistance_info" => {"TAX INFO" => nil,
                                        "INCOME" => nil,
                                        "INCOME ADJUSTMENTS" => nil,
                                        "HEALTH COVERAGE" => nil,
                                        "OTHER QUESTIONS" => nil}}]
    end

    before do
      allow(File).to receive(:read).with("./components/financial_assistance/app/views/financial_assistance/applications/raw_application_hra.yml.erb").and_return("")
      allow(File).to receive(:read).with("./components/financial_assistance/app/views/financial_assistance/applications/raw_application.yml.erb").and_return("")
      allow(YAML).to receive(:safe_load).with("").and_return(temp_file)
      user.update_attributes(roles: ["hbx_staff"])
    end

    it "should be successful" do
      application.update_attributes(:aasm_state => "submitted")
      get :raw_application, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end

    it "should redirect to applications page for draft application" do
      get :raw_application, params: { id: application.id }
      expect(response).to redirect_to(applications_path)
    end

    it "should redirect to applications page for invalid id" do
      get :raw_application, params: { id: FinancialAssistance::Application.new.id }
      expect(response).to redirect_to(applications_path)
    end

    it "should redirect to applications page for non hbx_staff roles" do
      user.update_attributes(roles: ["comsumer_role"])
      get :raw_application, params: { id: FinancialAssistance::Application.new.id }
      expect(response).to redirect_to(applications_path)
    end

    context "generate income hash" do
      it "should include unemployment income if feature enabled" do
        skip "skipped: unemployment income feature not enabled" unless FinancialAssistanceRegistry[:unemployment_income].enabled?

        application.update_attributes(:aasm_state => "submitted")
        get :raw_application, params: { id: application.id }
        # Translations are not resolved here. Only checking for presence of income keys.
        expect(assigns(:income_coverage_hash)[applicant.id]["INCOME"].present?).to eq true
      end
    end

    context "when the request type is invalid" do
      before do
        application.update_attributes(:aasm_state => "submitted")
      end

      it "should not render the raw_application template" do
        get :raw_application, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the raw_application template" do
        get :raw_application, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the raw_application template" do
        get :raw_application, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end
  end

  describe "PATCH update_application_year" do
    context "with different assistance_year" do
      before do
        patch :update_application_year, params: { id: application.id, application: {assistance_year: TimeKeeper.date_of_record.year + 1} }
      end
      it "should update the assistance_year" do
        expect(application.reload.assistance_year).to eq TimeKeeper.date_of_record.year + 1
      end
    end
  end

  describe  "GET wait_for_eligibility_response" do
    context "With valid data" do
      it "should redirect to eligibility_response_error if doesn't find the ED on wait_for_eligibility_response page" do
        get :wait_for_eligibility_response, params: { id: application.id }
        expect(assigns(:application)).to eq application
      end
    end

    context "when the request type is invalid" do
      before do
        application.update_attributes(:aasm_state => "submitted")
      end

      it "should not render the wait_for_eligibility_response template" do
        get :wait_for_eligibility_response, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the wait_for_eligibility_response template" do
        get :wait_for_eligibility_response, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the wait_for_eligibility_response template" do
        get :wait_for_eligibility_response, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end

    context "With missing family id" do
      it "should find application" do
        sign_in(admin_user)
        get :wait_for_eligibility_response, params: { id: application.id }, session: { person_id: application.family.primary_person.id }
        expect(assigns(:application)).to eq application
      end
    end
  end

  describe "GET eligibility_results" do
    context "With valid data" do
      it 'should get eligibility results' do
        get :eligibility_results, params: {:id => application.id, :cur => 1}
        expect(assigns(:application)).to eq application
        expect(response).to render_template(:financial_assistance_nav)
      end
    end

    context "With missing family id" do
      it 'should find the correct application' do
        sign_in(admin_user)
        get :eligibility_results, params: {:id => application.id, :cur => 1}, session: { person_id: application.family.primary_person.id }
        expect(assigns(:application)).to eq application
      end
    end
  end

  describe "GET application_publish_error" do
    context "With valid data" do

      it 'should get application publish error' do
        get :application_publish_error, params: { id: application.id }
        expect(assigns(:application)).to eq application
        expect(response).to render_template(:financial_assistance_nav)
      end
    end

    context "With missing family id" do
      let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let!(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
      let!(:permission) { FactoryBot.create(:permission, :super_admin) }
      let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

      it 'should find application with missing family id' do
        family.primary_person.consumer_role.move_identity_documents_to_verified
        sign_in(admin_user)
        get :application_publish_error, params: { id: application.id }, session: { person_id: family.primary_person.id }
        expect(assigns(:application)).to eq application
        expect(response).to render_template(:financial_assistance_nav)
      end
    end
  end

  describe "GET check eligibility results received" do
    context "doesn't have the success status code" do

      it "should return false" do
        get :check_eligibility_results_received, params: { id: application.id }
        expect(response.body).to eq "false"
      end
    end

    context 'with success status code and determined application' do

      let(:cache_key) { "application_#{application.hbx_id}_determined" }
      let(:set_rails_cache) { Rails.cache.write(cache_key, Time.now.strftime('%Y-%m-%d %H:%M:%S.%L'), expires_in: 5.minutes) }

      before do
        application.update_attributes(determination_http_status_code: 200, aasm_state: 'determined')
        set_rails_cache
        get :check_eligibility_results_received, params: { id: application.id }
      end

      after do
        Rails.cache.delete(cache_key)
      end

      it 'should return true for response body' do
        expect(response.body).to eq 'true'
      end
    end
  end

  context "with missing family id" do
    it "should find the correct application" do
      sign_in(admin_user)
      get :check_eligibility_results_received, params: { id: application.id }, session: { person_id: application.family.primary_person.id }
      expect(assigns(:application)).to eq application
    end
  end


  describe 'GET eligibility_response_error' do
    context 'where application did not receive eligibility determination' do
      before do
        get :eligibility_response_error, params: { id: application.id }
      end

      it 'should assign application to instance variable' do
        expect(assigns(:application)).to eq application
      end

      it "should update application's determination_http_status_code to 999" do
        expect(application.reload.determination_http_status_code).to eq(999)
      end

      it 'should render template eligibility_response_error' do
        expect(response).to render_template("eligibility_response_error")
      end
    end

    context "when the request type is invalid" do
      before do
        application.update_attributes(:aasm_state => "submitted")
      end

      it "should not render the eligibility_response_error template" do
        get :eligibility_response_error, params: { id: application.id }, format: :csv
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
        expect(response.media_type).to eq "text/csv"
      end

      it "should not render the eligibility_response_error template" do
        get :eligibility_response_error, params: { id: application.id }, format: :js
        expect(response.status).to eq 406
        expect(response.body).to eq "Unsupported format"
      end

      it "should not render the eligibility_response_error template" do
        get :eligibility_response_error, params: { id: application.id }, format: :xml
        expect(response.status).to eq 406
        expect(response.body).to eq "<error>Unsupported format</error>"
      end
    end

    context 'where application received eligibility determination' do
      before do
        application.update_attributes!(determination_http_status_code: 200, aasm_state: 'determined')
        get :eligibility_response_error, params: { id: application.id }
      end

      it 'should assign application to instance variable' do
        expect(assigns(:application)).to eq application
      end

      it 'should redirect to eligibility_results if application status is 200/203 and application is in determined state' do
        expect(response).to redirect_to(eligibility_results_application_path(application.id, cur: 1))
      end
    end

    context "with missing family id" do
      it "finds the correct application" do
        sign_in(admin_user)
        get :eligibility_response_error, params: { id: application.id }, session: { person_id: application.family.primary_person.id }
        expect(assigns(:application)).to eq application
      end
    end
  end
end

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  context "with :filtered_application_list on" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, first_name: "test1") }
    let(:user) { FactoryBot.create(:user, :person => person) }

    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:filtered_application_list).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_call_original
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:medicaid_gateway_determination).and_call_original
      Rails.application.reload_routes!
    end

    after do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:filtered_application_list).and_call_original
      Rails.application.reload_routes!
    end

    describe 'Feature flagged endpoints', type: :request do

      describe "GET /applications" do
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family.id, aasm_state: 'determined' }

        before(:each) do
          person.consumer_role.move_identity_documents_to_verified
          sign_in(user)
        end

        it 'succeeds' do
          get '/financial_assistance/applications'
          expect(response).to render_template(:index_with_filter)
        end

        context "when the request type is invalid" do
          let(:operation_instance) { instance_double(FinancialAssistance::Operations::Applications::QueryFilteredApplications) }
          let(:failure_result) { Dry::Monads::Result::Failure.new({message: "error message"}) }

          it "should not render the index_with_filter template" do
            allow(FinancialAssistance::Operations::Applications::QueryFilteredApplications).to receive(:new).and_return(operation_instance)
            allow(operation_instance).to receive(:call).and_return(failure_result)
            get '/financial_assistance/applications', params: { format: :csv }
            expect(response.status).to eq 406
            expect(response.body).to eq "Unsupported format"
            expect(response.media_type).to eq "text/csv"
          end

          it "should not render the index_with_filter template" do
            get '/financial_assistance/applications', params: { format: :fake }
            expect(response.status).to eq 406
            expect(response.body).to eq "Unsupported format"
          end

          it "should not render the index_with_filter template" do
            get '/financial_assistance/applications', params: { format: :xml }
            expect(response.status).to eq 406
            expect(response.body).to eq "<error>Unsupported format</error>"
          end
        end
      end
    end
  end

end

def setup_faa_data
  FinancialAssistance::Application.all.each do |faa|
    faa.applicants.each do |appl|
      params = {gender: 'female', dob: Date.today - 30.years}
      appl.update_attributes!(params)
    end
  end
end

def main_app
  Rails.application.class.routes.url_helpers
end
