# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicantsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 40.years)}
  let(:family_id) { BSON::ObjectId.new }
  let(:family_member_id) { BSON::ObjectId.new }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, id: family_id, person: person) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period) }
  let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: "draft",effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryBot.create(:applicant, application: application, dob: TimeKeeper.date_of_record - 40.years, is_primary_applicant: true, is_claimed_as_tax_dependent: false, is_self_attested_blind: false, has_daily_living_help: false,need_help_paying_bills: false, family_member_id: family_member_id) }
  let(:financial_assistance_applicant_valid) do
    {
      "is_ssn_applied" => "false",
      "non_ssn_apply_reason" => "we",
      "is_pregnant" => "false",
      "pregnancy_due_on" => "",
      "children_expected_count" => "",
      "is_post_partum_period" => "false",
      "pregnancy_end_on" => "09/21/2017",
      "is_former_foster_care" => "false",
      "foster_care_us_state" => "",
      "age_left_foster_care" => "",
      "is_student" => "false",
      "student_kind" => "",
      "student_status_end_on" => "",
      "student_school_kind" => "",
      "is_self_attested_blind" => "false",
      "has_daily_living_help" => "false",
      "need_help_paying_bills" => "false"
    }.tap do |params_hash|
      params_hash['is_primary_caregiver'] = "false" if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
    end
  end
  let(:financial_assistance_applicant_invalid) do
    {
      "is_required_to_file_taxes" => nil,
      "is_claimed_as_tax_dependent" => nil
    }
  end

  let(:applicant_params) do
    {
      "is_required_to_file_taxes" => true,
      "is_claimed_as_tax_dependent" => false,
      "has_job_income" => "false",
      "has_self_employment_income" => "false",
      "has_other_income" => "false",
      "has_deductions" => "false",
      "has_enrolled_health_coverage" => "false",
      "has_eligible_health_coverage" => "false"
    }.tap do |params_hash|
      params_hash['is_primary_caregiver'] = "false" if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
    end
  end

  before do
    # Tests to make sure it can handle admin user
    allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    sign_in(user)
  end

  context "GET other questions" do
    it "should assign applications", dbclean: :after_each do
      get :other_questions, params: { application_id: application.id, id: applicant.id }
      expect(assigns(:applicant).id).to eq applicant.id
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "GET save questions" do
    before do
      applicant.update_attributes(is_primary_caregiver: nil) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
    end
    it "should save questions and redirects to edit_financial_assistance_application_path", dbclean: :after_each do
      get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: financial_assistance_applicant_valid }
      expect(response).to have_http_status(302)
      expect(response.headers['Location']).to have_content 'edit'
      expect(response).to redirect_to(edit_application_path(application))
      if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
        applicant.reload
        expect(applicant.is_primary_caregiver.nil?).to eq(false)
      end
    end
    # TODO: This is run under the save context of :other_qns which runs the method presence_of_attr_other_qns and does not validate the is_required_to_file_taxes or
    # is_claimed_as_tax_dependent, which are passed as nil here as "invalid params."
    # Should they be added to the presence_of_attr_other_qns method?
    it "should not save and redirects to other_questions_financial_assistance_application_applicant_path", dbclean: :after_each do
      get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: financial_assistance_applicant_invalid }
      expect(response).to have_http_status(302)
      expect(response.headers['Location']).to have_content 'other_questions'
      expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
    end

    context "Pregnancy questions validation" do
      let(:faa_invalid_params_pregenancy) do
        {
          "is_pregnant" => true,
          "pregnancy_due_on" => nil,
          "children_expected_count" => nil
        }
      end

      let(:faa_without_due_date) do
        {
          "is_pregnant" => true,
          "pregnancy_due_on" => nil,
          "children_expected_count" => 1
        }
      end

      let(:faa_expected_count_nil) do
        {
          "is_pregnant" => true,
          "pregnancy_due_on" => (applicant.dob + 20.years).strftime("%m/%d/%Y"),
          "children_expected_count" => nil
        }
      end

      let(:faa_valid_params_pregenancy) do
        {
          "is_pregnant" => true,
          "pregnancy_due_on" => (applicant.dob + 20.years).strftime("%m/%d/%Y"),
          "children_expected_count" => 1
        }
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with invalid params", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_invalid_params_pregenancy }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with due date nill", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_without_due_date }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with children_expected_count nill", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_expected_count_nil }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should save and redirects to redirects to edit_financial_assistance_application_path with valid pregnancy responses", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_valid_params_pregenancy }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'edit'
        expect(response).to redirect_to(edit_application_path(application))
      end
    end

    context "is_post_partum_period" do
      let(:faa_invalid_post_partum_period_params) do
        {
          "is_post_partum_period" => true,
          "is_enrolled_on_medicaid" => nil,
          "pregnancy_end_on" => nil
        }
      end

      let(:faa_without_preg_end_date) do
        {
          "is_post_partum_period" => true,
          "pregnancy_end_on" => nil,
          "is_enrolled_on_medicaid" => true
        }
      end

      let(:faa_enrolled_on_medicaid_nil) do
        {
          "is_post_partum_period" => true,
          "pregnancy_end_on" => (applicant.dob + 20.years).strftime("%m/%d/%Y"),
          "is_enrolled_on_medicaid" => nil
        }
      end

      let(:faa_valid_params_partum_period_params) do
        {
          "is_post_partum_period" => true,
          "pregnancy_end_on" => (applicant.dob + 20.years).strftime("%m/%d/%Y"),
          "is_enrolled_on_medicaid" => true
        }
      end

      let(:partum_period_params_with_out_enrolled_on_medicaid_params) do
        {
          "is_pregnant" => "false",
          "pregnancy_due_on" => "",
          "children_expected_count" => "",
          "is_post_partum_period" => "true",
          "pregnancy_end_on" => (TimeKeeper.date_of_record - 1.month).strftime("%m/%d/%Y")
        }
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with invalid params", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_invalid_post_partum_period_params }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with end date nil", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_without_preg_end_date }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should save and redirects to redirects to edit_financial_assistance_application_path with enrolled_on_medicaid nil", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_enrolled_on_medicaid_nil }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'edit'
        expect(response).to redirect_to(edit_application_path(application))
      end

      it "should save and redirects to redirects to edit_financial_assistance_application_path with valid params", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: faa_valid_params_partum_period_params }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'edit'
        expect(response).to redirect_to(edit_application_path(application))
      end

      context "when applicant not applying for coverage and in post_partum_period" do
        it "should not return Was This Person On Medicaid During Pregnancy?' Should Be Answered error" do
          applicant.update_attributes(is_enrolled_on_medicaid: nil, is_applying_coverage: false)
          get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: partum_period_params_with_out_enrolled_on_medicaid_params }
          expect(response).to have_http_status(302)
          expect(response.headers['Location']).to have_content 'edit'
          expect(response).to redirect_to(edit_application_path(application))
        end
      end
    end

    context "age_of_applicant" do
      let(:is_invalid_former_foster_care) do
        {
          "is_former_foster_care" => true,
          "foster_care_us_state" => nil,
          "age_left_foster_care" => nil
        }
      end

      let(:is_invalid_former_foster_care1) do
        {
          "is_former_foster_care" => true,
          "foster_care_us_state" => "DC",
          "age_left_foster_care" => nil
        }
      end

      let(:is_valid_former_foster_care) do
        {
          "is_former_foster_care" => true,
          "foster_care_us_state" => "DC",
          "age_left_foster_care" => 1
        }.tap do |params_hash|
          params_hash['is_primary_caregiver'] = "false" if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
        end
      end

      before :each do
        applicant.update_attributes(is_applying_coverage: true,
                                    dob: TimeKeeper.date_of_record - 20.years,
                                    is_post_partum_period: true,
                                    pregnancy_end_on: applicant.dob + 20.years,
                                    is_enrolled_on_medicaid: true)
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with invalid params", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: {} }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with foster_care_us_state nill", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: is_invalid_former_foster_care }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should not save and redirects to other_questions_financial_assistance_application_applicant_path with age_left_foster_care nill", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: is_invalid_former_foster_care1 }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'other_questions'
        expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
      end

      it "should save and redirects to edit_financial_assistance_application_path with valid params", dbclean: :after_each do
        get :save_questions, params: { application_id: application.id, id: applicant.id, applicant: is_valid_former_foster_care }
        expect(response).to have_http_status(302)
        expect(response.headers['Location']).to have_content 'edit'
        expect(response).to redirect_to(edit_application_path(application))
      end
    end
  end

  context "POST step" do
    before do
      controller.instance_variable_set(:@modal, application)
    end

    it "should render step if no key present in params with modal_name" do
      post :step, params: { application_id: application.id, id: applicant.id }
      expect(response).to render_template 'workflow/step'
    end

    context "when params has application key" do
      it "When model is saved" do
        post :step, params: { application_id: application.id, id: applicant.id, applicant: financial_assistance_applicant_valid }
        expect(applicant.save).to eq true
      end

      it "should redirect to income index when in last step (tax_info)" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: applicant_params, last_step: true }
        expect(response.headers['Location']).to have_content 'incomes'
        expect(response.status).to eq 302
        expect(response).to redirect_to(application_applicant_incomes_path(application, applicant))
      end

      it "should not redirect to find_applicant_path when not passing params last step" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: applicant_params }
        expect(response.status).to eq 200
        expect(response).to render_template 'workflow/step'
      end

      it "should render_template 'workflow/step' when params are invalid" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: financial_assistance_applicant_invalid}
        expect(response).to render_template 'workflow/step'
      end
    end

    it "should render step if model is not saved" do
      post :step, params: { application_id: application.id, id: applicant.id }
      expect(response).to render_template 'workflow/step'
    end
  end

  context "DELETE destroy" do
    let(:dependent1) { FactoryBot.create(:person) }
    let(:family_member_dependent) { FactoryBot.build(:family_member, person: dependent1, family: family)}
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        first_name: "James", last_name: "Bond", gender: "male", dob: Date.new(1993, 3, 8),
                        person_hbx_id: dependent1.hbx_id,
                        application: application,
                        family_member_id: family_member_dependent.id)
    end

    before do
      family.family_members << family_member_dependent
      family.save
      relation = PersonRelationship.new(relative: family.family_members.last.person, kind: "child")
      person.person_relationships << relation
      person.save
    end

    it "should redirect to edit application path" do
      delete :destroy, params: { application_id: application.id, id: applicant.id }
      expect(response).to redirect_to(edit_application_path(application))
    end

    it "should destroy the applicant" do
      delete :destroy, params: { application_id: application.id, id: applicant2.id }
      application.reload
      expect(application.active_applicants.where(id: applicant2.id).first).to be_nil
    end

    it "should not destroy the primary applicant" do
      expect(applicant.is_primary_applicant).to eq true
      delete :destroy, params: { application_id: application.id, id: applicant.id }
      application.reload
      expect(application.active_applicants.where(id: applicant.id).first).to eq applicant
    end

    it "should destroy the dependent" do
      expect(family.family_members.active.count).to eq 2
      delete :destroy, params: { application_id: application.id, id: applicant2.id }
      family.reload
      expect(family.family_members.active.count).to eq 1
    end

    it "should destroy the primary dependent" do
      expect(applicant.is_primary_applicant).to eq true
      expect(family.family_members.active.count).to eq 2
      delete :destroy, params: { application_id: application.id, id: applicant.id }
      family.reload
      expect(family.family_members.active.count).to eq 2
    end
  end

  context "GET age of applicant" do
    it "should return age of applicant", dbclean: :after_each do
      get :age_of_applicant, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response.body).to eq person.age_on(TimeKeeper.date_of_record).to_s
    end
  end

  context "GET primary_applicant_has_spouse" do
    it "should check for primary_applicant_has_spouse", dbclean: :after_each do
      get :primary_applicant_has_spouse, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response.body).to eq "false"
    end
  end
end
