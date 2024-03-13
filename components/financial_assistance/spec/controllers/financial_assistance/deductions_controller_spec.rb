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

  before do
    person.consumer_role.move_identity_documents_to_verified
    sign_in(user)
  end

  context "POST create" do
    let(:input_params) do
      {
        application_id: application.id,
        applicant_id: applicant.id,
        deduction: {
          amount: "$200.00",
          frequency_kind: "biweekly",
          start_on: "1/1/#{TimeKeeper.datetime_of_record.year}",
          end_on: "12/31/#{TimeKeeper.datetime_of_record.year}",
          kind: "student_loan_interest"
        }
      }
    end

    before do
      @applicant = applicant
      post :create, params: input_params, format: :js
    end

    it "should create with valid params" do
      expect(response.status).to eq(200)
    end
  end
end
