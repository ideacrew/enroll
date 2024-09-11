# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe FinancialAssistance::BenefitsController, dbclean: :after_each, type: :controller do
    routes { FinancialAssistance::Engine.routes }

    let(:hbx_profile) do
      FactoryBot.create(
        :hbx_profile,
        :normal_ivl_open_enrollment,
        us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
        cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0"
      )
    end
    let(:hbx_staff_role) do
      person.create_hbx_staff_role(
        permission_id: permission.id,
        subrole: permission.name,
        hbx_profile: hbx_profile
      )
    end
    let(:user) do
      FactoryBot.create(:user, person: person)
      hbx_staff_role.person.user
    end
    let(:permission) { FactoryBot.create(:permission, :super_admin) }
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family_id) { BSON::ObjectId.new }
    let(:family_member_id) { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: 'draft',effective_date: TimeKeeper.date_of_record) }
    let!(:applicant) { FactoryBot.create(:applicant, application: application,family_member_id: family_member_id) }
    let!(:benefit) do
      benefit = FactoryBot.build(:financial_assistance_benefit)
      applicant.benefits << benefit
      benefit
    end
    let!(:valid_params1) do
      {
        'kind' => 'is_eligible',
        'start_on' => '09/04/2017',
        'end_on' => '09/20/2017',
        'insurance_kind' => 'child_health_insurance_plan',
        'esi_covered' => 'self',
        'employer_name' => '',
        'employer_id' => '',
        'employee_cost' => '',
        'employee_cost_frequency' => ''
      }
    end
    let!(:invalid_params) do
      {
        'kind' => 'pp',
        'start_on' => '09/04/2017',
        'end_on' => '09/20/2017',
        'insurance_kind' => 'child_health_insurance_plan',
        'esi_covered' => 'self',
        'employer_name' => '',
        'employer_id' => '',
        'employee_cost' => '',
        'employee_cost_frequency' => ''
      }
    end
    let(:employer_address){ {'address_1' => '', 'address_2' => '', 'city' => '', 'state' => '', 'zip' => ''}}
    let(:employer_phone) {{'full_phone_number' => ''}}

    before do
      person.consumer_role.move_identity_documents_to_verified
      sign_in(user)
    end

    context 'GET index' do
      it 'should render template financial assistance' do
        get :index, params: { application_id: application.id, applicant_id: applicant.id }
        expect(response).to render_template(:financial_assistance_nav)
      end

      context "when the request type is invalid" do
        it "should not render the raw_application template" do
          get :index, params: { application_id: application.id, applicant_id: applicant.id }, format: :csv
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
          expect(response.media_type).to eq "text/csv"
        end

        it "should not render the raw_application template" do
          get :index, params: { application_id: application.id, applicant_id: applicant.id }, format: :js
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
        end

        it "should not render the raw_application template" do
          get :index, params: { application_id: application.id, applicant_id: applicant.id }, format: :xml
          expect(response.status).to eq 406
          expect(response.body).to eq "<error>Unsupported format</error>"
        end
      end
    end

    context 'POST new' do
      it 'should load template work flow steps' do
        post :new, params: { application_id: application.id, applicant_id: applicant.id }
        expect(response).to render_template(:financial_assistance_nav)
        expect(response).to render_template 'index'
      end

      context "when the request type is invalid" do
        it "should not render the raw_application template" do
          post :new, params: { application_id: application.id, applicant_id: applicant.id }, format: :csv
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
          expect(response.media_type).to eq "text/csv"
        end

        it "should not render the raw_application template" do
          post :new, params: { application_id: application.id, applicant_id: applicant.id }, format: :js
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
        end

        it "should not render the raw_application template" do
          post :new, params: { application_id: application.id, applicant_id: applicant.id }, format: :xml
          expect(response.status).to eq 406
          expect(response.body).to eq "<error>Unsupported format</error>"
        end
      end
    end

    context "create" do
      it "should create a benefit instance" do
        create_params = {
          application_id: application.id,
          applicant_id: applicant.id,
          benefit: {start_on: "09/04/2017",
                    end_on: "09/20/2017"}
        }
        post :create, params: create_params, format: :js
        expect(applicant.benefits.count).to eq 1
      end

      it "should able to save an benefit instance with the 'to' field blank " do
        create_params = {
          application_id: application.id,
          applicant_id: applicant.id,
          benefit: {start_on: "09/04/2017", end_on: " "}
        }
        post :create, params: create_params, format: :js
        expect(applicant.benefits.count).to eq 1
      end

      context "when the request type is invalid" do
        let(:create_params) do
          {
            application_id: application.id,
            applicant_id: applicant.id,
            benefit: {start_on: "09/04/2017", end_on: " "}
          }
        end

        it "should not render the raw_application template" do
          post :create, params: create_params, format: :csv
          expect(response.status).to eq 406
          expect(response.body).to eq "Unsupported format"
          expect(response.media_type).to eq "text/csv"
        end

        it "should not render the raw_application template" do
          post :create, params: create_params, format: :xml
          expect(response.status).to eq 406
          expect(response.body).to eq "<error>Unsupported format</error>"
        end
      end
    end

    context 'destroy' do
      it 'should delete a benefit instance' do
        expect(applicant.benefits.count).to eq 1
        delete :destroy, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id }
        applicant.reload
        expect(applicant.benefits.count).to eq 0
      end
    end
  end
end
