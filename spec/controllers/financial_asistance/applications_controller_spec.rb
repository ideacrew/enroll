require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, type: :controller do
  render_views
  let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :person => person, oim_id: "mahesh.")}
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let!(:plan) { FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01") }
  let!(:application) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryGirl.create(:applicant, application: application, is_claimed_as_tax_dependent:false, is_self_attested_blind:false, has_daily_living_help:false,need_help_paying_bills:false, family_member_id: family.primary_applicant.id) }
  let!(:application2) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant2) { FactoryGirl.create(:applicant, application: application2, family_member_id: family.primary_applicant.id) }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

  before do
    sign_in(user)
  end

  context "GET Index" do
    it "should assign applications", dbclean: :after_each do
      get :index
      expect(assigns(:family)).to eq person.primary_family
      expect(assigns(:applications)).to eq family.applications
    end
  end

  context "GET new" do
    it "should assign application" do
      get :new
      expect(assigns(:application).class).to eq FinancialAssistance::Application
    end
  end

  context "POST create" do
    it "should redirect" do
      post :create
      expect(response).to be_redirect
    end
  end

  context "GET edit" do
    it "should render" do
      get :edit, id: application.id
      expect(assigns(:family)).to eq person.primary_family
      expect(assigns(:application)).to eq application
      expect(assigns(:missing_relationships)).to eq family.find_missing_relationships(family.build_relationship_matrix)
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "POST step" do
    before do
      controller.instance_variable_set(:@modal, application)
    end

    it "should render step if no key present in params with modal_name" do
      post :step, id: application.id
      expect(response).to render_template 'workflow/step'
    end

    context "when params has application key" do
      it "When model is saved" do
        post :step, id: application.id, application: {"medicaid_terms"=>"yes", "report_change_terms"=>"yes", "medicaid_insurance_collection_terms"=>"yes", "parent_living_out_of_home_terms"=>"true", "attestation_terms"=>"yes", "submission_terms"=>"yes"}
        expect(application.save).to eq true
      end

      it "should fail during publish application and redirects to error_page" do
        post :step, id: application2.id, commit: "Submit Application", application: {"medicaid_terms"=>"yes", "report_change_terms"=>"yes", "medicaid_insurance_collection_terms"=>"yes", "parent_living_out_of_home_terms"=>"true", "attestation_terms"=>"yes", "submission_terms"=>"yes"}
        expect(response).to redirect_to(application_publish_error_financial_assistance_application_path(application2))
      end

      it "should successfully publish application and redirects to wait_for_eligibility" do
        post :step, id: application.id, commit: "Submit Application", application: {"medicaid_terms"=>"yes", "report_change_terms"=>"yes", "medicaid_insurance_collection_terms"=>"yes", "parent_living_out_of_home_terms"=>"true", "attestation_terms"=>"yes", "submission_terms"=>"yes"}
        expect(response).to redirect_to(wait_for_eligibility_response_financial_assistance_application_path(application))
      end
    end
    it "should render step if model is not saved" do
      post :step, id: application.id
      expect(response).to render_template 'workflow/step'
    end
  end

  context "generate_payload" do
    it "should execute action generate_payload" do
      allow(controller).to receive(:render_to_string).with(
        "events/financial_assistance_application", {:formats => ["xml"], :locals => { :financial_assistance_application => application }}).and_return(application)
    end
  end

  context "GET copy" do
    before do
      family.applications.each { |app| app.update_attributes(aasm_state: "determined")}
    end
    it 'should redirect' do
      get :copy, id: application.id
      expect(response).to be_redirect
    end
  end

  context "GET help_paying_coverage" do
    let(:id) { "_id" }
    it 'should assign application id to transaction id' do
      get :help_paying_coverage, id: id
      expect(assigns(:transaction_id)).to eq id
    end
  end

  context "GET review_and_submit" do
    it 'should render review and submit page' do
      application.update_attributes(:aasm_state => "draft")
      get :review_and_submit, id: application.id
      expect(assigns(:consumer_role)).to eq person.consumer_role
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "GET wait_for_eligibility_response" do
    it 'should wait for eligibility response' do
      get :wait_for_eligibility_response, id: application.id
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
    end
  end

  context "GET eligibility_results" do
    it 'should get eligibility results' do
      get :eligibility_results, id: application.id
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "GET application_publish_error" do
    it 'should get application publish error' do
      get :application_publish_error, id: application.id
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

end
