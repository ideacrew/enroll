# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::DetermineAll, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
  end

  let(:current_date) { TimeKeeper.date_of_record }
  let(:current_year) { current_date.year }
  let(:renewal_year) { current_year.next }

  let!(:person) do
    FactoryBot.create(:person, :with_consumer_role, first_name: 'test10', last_name: 'test30', gender: 'male', hbx_id: '100095')
  end

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person)
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111000222',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      assistance_year: current_year,
                      full_medicaid_determination: true)
  end

  let!(:renewal_application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111222333',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      predecessor_id: application.id,
                      aasm_state: 'renewal_draft',
                      assistance_year: renewal_year,
                      full_medicaid_determination: true)
  end

  let!(:prospective_determined_application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '11122233344',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      aasm_state: 'determined',
                      assistance_year: renewal_year,
                      full_medicaid_determination: true)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      family_member_id: family.primary_applicant.id,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                      application: application)
  end

  let(:event) { Success(double) }
  let(:operation_instance) { described_class.new }

  let!(:household) { FactoryBot.create(:household, family: family) }
  let(:effective_on) { current_date.beginning_of_year}

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      kind: "individual",
                      coverage_kind: "health",
                      aasm_state: 'coverage_selected',
                      effective_on: effective_on,
                      hbx_enrollment_members: [
                        FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: effective_on, coverage_start_on: effective_on, is_subscriber: true)
                      ])
  end

  before do
    allow(operation_instance.class).to receive(:new).and_return(operation_instance)
    allow(event.success).to receive(:publish).and_return(true)
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         :county => 'Cumberland')]
      appl.save!
    end
  end

  context 'success' do
    context 'with renewal application' do
      before do
        @result = subject.call({ renewal_year: renewal_year })
      end

      it 'returns array of renewal applications' do
        expect(@result.success).to include(renewal_application.id)
        expect(@result.success).not_to include(prospective_determined_application.id)
      end
    end
  end

  context 'failure' do
    context 'with invalid params' do
      let(:invalid_params) { [{ renewal_year: renewal_year.to_s }, {}].sample }

      before do
        @result = subject.call(invalid_params)
      end

      it 'returns a failure result' do
        expect(@result.failure?).to be_truthy
      end
    end
  end
end
