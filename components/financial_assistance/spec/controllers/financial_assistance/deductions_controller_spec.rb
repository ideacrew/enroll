# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::DeductionsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 40.years)}
  let(:family_id) { BSON::ObjectId.new }
  let(:family_member_id) { BSON::ObjectId.new }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, id: family_id, person: person) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period) }
  let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: "draft",effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      is_claimed_as_tax_dependent: false,
                      is_self_attested_blind: false,
                      has_daily_living_help: false,
                      need_help_paying_bills: false,
                      family_member_id: family_member_id)
  end
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
    }
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
    }
  end

  before do
    sign_in(user)
  end

  context "POST create" do
    it "should create with valid params" do
      @applicant = applicant
      post :create, params: {application_id: application.id,
                             applicant_id: applicant.id,
                             deduction: {amount: "$200.00",
                                         frequency_kind: "biweekly",
                                         start_on: Date.new(Date.today.year, 1, 1),
                                         end_on: Date.new(Date.today.year, 12, 31),
                                         kind: "student_loan_interest"}}, format: :js
      expect(response.status).to eq(200)
    end
  end
end
