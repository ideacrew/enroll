# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Verifications::PublishFaaTotalIneligibilityNotice, dbclean: :after_each do
  include Dry::Monads[:do, :result]
  include_context 'cms ME simple_scenarios test_case_d'

  let!(:person) { FactoryBot.create(:person, :with_ssn, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      aasm_state: 'determined',
                      hbx_id: "830293",
                      effective_date: TimeKeeper.date_of_record.beginning_of_year,
                      eligibility_response_payload: response_payload.to_json)
  end
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
                      is_student: false,
                      is_former_foster_care: false,
                      is_post_partum_period: false)
  end
  let!(:create_home_address) do
    add = ::FinancialAssistance::Locations::Address.new({
                                                          kind: 'home',
                                                          address_1: '3 Awesome Street',
                                                          address_2: '#300',
                                                          city: 'Washington',
                                                          state: 'DC',
                                                          zip: '20001'
                                                        })
    applicant.addresses << add
    applicant.save!
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let(:event) { Success(double) }
  let(:obj)  { ::FinancialAssistance::Operations::Applications::Verifications::FaaTotalIneligibilityNotice.new }

  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}}
    }
  end

  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}}
    }
  end

  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}
    }
  end

  let(:fetch_double) { double(:new => double(call: double(:value! => premiums_hash, :failure? => false, :success => premiums_hash)))}
  let(:fetch_slcsp_double) { double(:new => double(call: double(:value! => slcsp_info, :failure? => false, :success => slcsp_info)))}
  let(:fetch_lcsp_double) { double(:new => double(call: double(:value! => lcsp_info, :failure? => false, :success => lcsp_info)))}
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }


  before do
    allow(::FinancialAssistance::Operations::Applications::Verifications::FaaTotalIneligibilityNotice).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
  end

  context 'success' do
    context 'with valid application' do
      before do
        @result = subject.call(application)
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to eq('Successfully published the payload for FAA Total Ineligibility Notice')
      end
    end
  end


  context 'failure' do
    context 'invalid application id' do
      before do
        @result = subject.call('application_id')
      end

      it 'should return a failure with error message' do
        expect("Invalid Application object application_id, expected FinancialAssistance::Application")
      end
    end

    context 'missing eligibility results' do
      before do
        application.update_attributes!(eligibility_response_payload: nil)
        @result = subject.construct_payload(application)
      end

      it 'should return a failure with error message' do
        expect("PublishFaaTotalIneligibilityNotice_error: Could not initialize application for undetermined application #{application.id}")
      end
    end
  end
end
