# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckApplication, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:application_id) { "614cd09ca54d7584cbc9532d" }

  let(:person_id) { "b3dc8e08e28e487f80285fb79681b337" }

  let(:payload) do
    {
      application_identifier: application_id,
      family_identifier: "10453",
      applicant_responses: { person_id => "Applicant Not Found" },
      type: "application"
    }
  end

  let(:invalid_payload) do
    {
      application_identifier: "invalid",
      family_identifier: "10453",
      applicant_responses: { b3dc8e08e28e487f80285fb79681b337: "Applicant Not Found" }
    }
  end

  let!(:person) { FactoryBot.create(:person, hbx_id: "b3dc8e08e28e487f80285fb79681b337") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      id: application_id)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      first_name: person.first_name,
                      last_name: person.last_name,
                      dob: person.dob,
                      gender: person.gender,
                      ssn: person.ssn,
                      application: application,
                      person_hbx_id: person.hbx_id,
                      ethnicity: [],
                      is_primary_applicant: true,
                      is_self_attested_blind: false,
                      is_applying_coverage: true,
                      is_required_to_file_taxes: true,
                      is_pregnant: false,
                      has_job_income: false,
                      has_self_employment_income: false,
                      has_unemployment_income: false,
                      has_other_income: false,
                      has_deductions: false,
                      has_enrolled_health_coverage: false,
                      has_eligible_health_coverage: false,
                      has_eligible_medicaid_cubcare: false,
                      is_claimed_as_tax_dependent: false,
                      is_incarcerated: false,
                      is_post_partum_period: false)
  end

  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckApplication.new }

  context 'Given an invalid payload' do
    it 'should fail' do
      result = operation.call(invalid_payload)
      expect(result).not_to be_success
    end
  end

  context 'Given a valid payload' do

    before :each do
      @result = operation.call(payload)
    end

    it 'should be successful' do
      expect(@result).to be_success
    end

    it 'should update the Application has_mec_check_response field to true' do
      updated_application = FinancialAssistance::Application.find(application_id)
      expect(updated_application.has_mec_check_response).to eq true
    end

    it 'should update the Person MEC check response' do
      updated_person = Person.find_by(hbx_id: person_id)
      expect(updated_person.mec_check_response).to eq "Applicant Not Found"
    end

    it 'should update the Person MEC check date' do
      updated_person = Person.find_by(hbx_id: person_id)
      expect(updated_person.mec_check_date).not_to be_nil
    end
  end
end