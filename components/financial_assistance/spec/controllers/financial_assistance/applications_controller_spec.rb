# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}
  let(:effective_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:application_period) {effective_on.beginning_of_year..effective_on.end_of_year}

  describe "HBX admin" do
    context "inferring FA app's family_id" do
      before do
        sign_in(user)
        allow(user).to receive(:try).with(:has_hbx_staff_role?).and_return(true)
      end
      it "should set properly even when logged in as admin" do
        application = FinancialAssistance::Application.create!(family_id: family_id)
        get :index
        expect(assigns(:applications).to_a).to eq([application])
      end
    end
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
  end

  context "copy an application" do
    let(:family1_id) { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family1_id, aasm_state: 'determined' }

    before(:each) do
      sign_in user
      applicants = application.applicants
      application.add_or_update_relationships(applicants[0], applicants[1], 'spouse')
      application.add_or_update_relationships(applicants[0], applicants[2], 'parent')
      application.add_or_update_relationships(applicants[0], applicants[3], 'parent')
      application.add_or_update_relationships(applicants[1], applicants[2], 'parent')
      application.add_or_update_relationships(applicants[1], applicants[3], 'parent')
      application.add_or_update_relationships(applicants[2], applicants[3], 'sibling')
      application.relationships << ::FinancialAssistance::Relationship.new(kind: 'spouse', applicant_id: applicants[0].id, relative_id: applicants[1].id)
      application.relationships << ::FinancialAssistance::Relationship.new(kind: 'spouse', applicant_id: applicants[0].id, relative_id: applicants[1].id)

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

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  routes { FinancialAssistance::Engine.routes }
  let(:event) { Success(double) }
  let(:obj)  { FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: 1234)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}
  let(:family_member_id) { family.primary_applicant.id }
  let!(:application) { FactoryBot.create(:application, hbx_id: 1234, assistance_year: Date.today.year, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
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
  let!(:application2) { FactoryBot.create(:application, hbx_id: 3456, assistance_year: Date.today.year, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
  let!(:applicant2) { FactoryBot.create(:applicant, application: application2,  family_member_id: family_member_id) }
  let(:application_valid_params) { {"medicaid_terms" => "yes", "report_change_terms" => "yes", "medicaid_insurance_collection_terms" => "yes", "parent_living_out_of_home_terms" => "true", "attestation_terms" => "yes", "submission_terms" => "yes"} }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period)}

  before do
    allow(person).to receive(:financial_assistance_identifier).and_return(family_id)
    sign_in(user)
  end

  context "GET Index" do
    it "should assign applications", dbclean: :after_each do
      get :index
      applications = FinancialAssistance::Application.where(:family_id.in => [family_id])
      expect(assigns(:applications)).to eq applications
    end
  end

  context "GET new" do
    it "should assign application" do
      get :new
      expect(assigns(:application).class).to eq FinancialAssistance::Application
    end
  end

  context "GET edit" do
    it "should render" do
      get :edit, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "POST step" do
    before do
      allow(controller).to receive(:haven_determination_is_enabled?).and_return(true)
      setup_faa_data
      allow(FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
      allow(obj).to receive(:build_event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
      controller.instance_variable_set(:@model, application.reload)
    end

    it "showing errors when @model does not save" do
      # to give errors
      allow(application).to receive_message_chain('errors.full_messages').and_return(
        ["Hbx id can't be blank", "fake errors can't be blank"]
      )
      allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
      allow(application).to receive(:save).and_return(false)
      allow(application).to receive(:save!).with(validate: false).and_return(false)
      allow(application).to receive(:valid?).and_return(false)
      post :step, params: {application: application.attributes, id: application.id }
      expect(flash[:error]).to eq("Hbx id can't be blank, fake errors can't be blank")
    end

    it "showing errors when @model does not save and errors blank" do
      # to give errors
      allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
      allow(application).to receive(:save).and_return(false)
      allow(application).to receive(:save!).with(validate: false).and_return(false)
      allow(application).to receive(:valid?).and_return(false)
      post :step, params: {application: application.attributes, id: application.id }
      expect(flash[:error]).to eq("")
    end

    it "should render step if no key present in params with modal_name" do
      post :step, params: { id: application.id }
      expect(response).to render_template 'workflow/step'
    end

    context "submit step with a valid but incomplete application" do
      before do
        application.update_attributes!(aasm_state: 'draft')
        allow(application).to receive(:complete?).and_return(false)
        allow(application).to receive(:save).and_return(true)
        allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
        allow(controller).to receive(:build_error_messages)

        post :step, params: { id: application.id, commit: 'Submit Application', application: application_valid_params }
      end

      it 'build errors for the model' do
        expect(controller).to have_received(:build_error_messages).with(application)
      end

      it "should render error page when there is an incomplete or already submitted application" do
        expect(response).to redirect_to(application_publish_error_application_path(application))
      end
    end

    context "submit step with a publish_result failure" do
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

        post :step, params: { id: application.id, commit: 'Submit Application', application: application_valid_params }
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

      it "When model is saved" do
        post :step, params: { id: application.id, application: application_valid_params }
        expect(application.save).to eq true
      end

      it "should fail during publish application and redirects to error_page" do
        post :step, params: { id: application2.id, commit: "Submit Application", application: application_valid_params }
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
        post :step, params: { id: application.id, commit: "Submit Application", application: application_valid_params }
        expect(response).to redirect_to(wait_for_eligibility_response_application_path(application))
      end
    end

    it "should render step if model is not saved" do
      post :step, params: { id: application.id }
      expect(response).to render_template 'workflow/step'
    end
  end

  context "GET copy" do
    context "when there is not response from eligibility service" do

      before do
        FinancialAssistance::Application.where(family_id: family_id).each {|app| app.update_attributes(aasm_state: "determined")}
      end

      it 'should copy applicant and redirect to financial assistance application edit path' do
        get :copy, params: { id: application.id }
        existing_app_ids = [application.id, application2.id]
        copy_app = FinancialAssistance::Application.where(family_id: family_id).reject {|app| existing_app_ids.include? app.id}.first
        expect(response).to redirect_to(edit_application_path(copy_app.id))
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
  end

  context "uqhp_flow" do
    it "should redirect to insured family members" do
      get :uqhp_flow
      expect(FinancialAssistance::Application.where(family_id: family_id, aasm_state: "draft").count).to eq 0
      expect(response).to redirect_to(main_app.insured_family_members_path(consumer_role_id: person.consumer_role.id))
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
  end

  context "GET review" do
    it "should be successful" do
      application.update_attributes(:aasm_state => "submitted")
      get :review, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end

    it "should redirect to applications page" do
      get :review, params: { id: FinancialAssistance::Application.new.id }
      expect(response).to redirect_to(applications_path)
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
  end

  context "GET wait_for_eligibility_response" do
    it "should redirect to eligibility_response_error if doesn't find the ED on wait_for_eligibility_response page" do
      get :wait_for_eligibility_response, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end
  end

  context "GET eligibility_results" do
    it 'should get eligibility results' do
      get :eligibility_results, params: {:id => application.id, :cur => 1}
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "GET application_publish_error" do
    it 'should get application publish error' do
      get :application_publish_error, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "check eligibility results received" do
    it "should return false if the Header of the response doesn't have the success status code" do
      get :check_eligibility_results_received, params: { id: application.id }
      expect(response.body).to eq "false"
    end

    context 'with success status code and determined application' do
      before do
        application.update_attributes(determination_http_status_code: 200, aasm_state: 'determined')
        get :check_eligibility_results_received, params: { id: application.id }
      end

      it 'should return true for response body' do
        expect(response.body).to eq 'true'
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
