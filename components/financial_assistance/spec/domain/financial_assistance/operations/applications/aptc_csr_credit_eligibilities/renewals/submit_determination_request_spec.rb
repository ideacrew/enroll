# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let!(:person) { FactoryBot.create(:person, :with_ssn, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'draft', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
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
  let(:obj)  { ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest.new }
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

  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }

  let(:fetch_double) { double(:new => double(call: premiums_double))}
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}

  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:out_of_state_primary)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    allow(::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  context 'success' do
    context 'with valid application' do
      before do
        @result = subject.call({application_id: application.id})
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to match(/Successfully Published for event determination_requested/)
      end
    end

    context 'with indian_alaskan_tribe_details feature' do
      context 'enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(true)
          applicant.update_attributes!(tribal_name: "tribe name", tribal_state: "ME")
          @result = subject.call({application_id: application.id})
        end

        it 'should return success' do
          expect(@result).to be_success
        end

        it 'should return success with message' do
          expect(@result.success).to match(/Successfully Published for event determination_requested/)
        end
      end

      context 'disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
          applicant.update_attributes!(tribal_id: "4848477")
          @result = subject.call({application_id: application.id})
        end

        it 'should return success' do
          expect(@result).to be_success
        end

        it 'should return success with message' do
          expect(@result.success).to match(/Successfully Published for event determination_requested/)
        end
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
        application.update_attributes!(aasm_state: 'submitted')
        @result = subject.call({application_id: application.id})
      end

      it 'should return a failure with error message' do
        expect(@result.failure.present?).to be_truthy
      end
    end
  end
end
