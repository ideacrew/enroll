# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
  let!(:applicant) do
    FactoryBot.create(:applicant,
                      first_name: person.first_name,
                      last_name: person.last_name,
                      dob: person.dob,
                      gender: person.gender,
                      ssn: person.ssn,
                      application: application,
                      eligibility_determination_id: eligibility_determination.id,
                      citizen_status: 'us_citizen',
                      person_hbx_id: person.hbx_id,
                      ethnicity: [],
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
                      is_student: false,
                      is_former_foster_care: false,
                      is_post_partum_period: false)
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  context 'success' do
    context 'with valid application' do
      before do
        @result = subject.call({application_id: application.id})
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to eq('Successfully published the payload to medicaid_gateway for determination')
      end
    end
  end

  context 'failure' do
    context 'invalid application id' do
      before do
        @result = subject.call({application_id: 'application_id'})
      end

      it 'should return a failure with error message' do
        expect(@result.failure).to eq('Unable to find Application with ID application_id.')
      end
    end

    context 'invalid application aasm_state' do
      before do
        application.update_attributes!(aasm_state: 'draft')
        @result = subject.call({application_id: application.id})
      end

      it 'should return a failure with error message' do
        expect(@result.failure).to eq('Application is in draft state. Please submit application.')
      end
    end

    context 'invalid applicant for publish context' do
      before do
        applicant.update_attributes!(citizen_status: nil)
        @result = subject.call({application_id: application.id})
      end

      it 'should return a failure with error message' do
        err = { applicants: { 0 => { citizenship_immigration_status_information: { citizen_status: ['must be filled'] } } } }
        expect(@result.failure.errors.to_h).to eq(err)
      end
    end
  end
end
