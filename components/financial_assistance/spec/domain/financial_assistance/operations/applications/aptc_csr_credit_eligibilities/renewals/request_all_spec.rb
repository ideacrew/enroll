# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestAll, dbclean: :after_each do
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
                      aasm_state: 'determined',
                      assistance_year: current_year,
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
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year}

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

  context 'for success' do
    context 'query and publish renewal draft application' do
      before do
        @result = subject.call(renewal_year: renewal_year)
      end

      it 'should return IVL family id' do
        expect(@result.success.first).to eq family.id
      end
    end

    describe '#find_families' do
      context 'skip_eligibility_redetermination is enabled' do
        let!(:family2) do
          FactoryBot.create(:family, :with_primary_family_member)
        end
        let!(:application2) do
          FactoryBot.create(:financial_assistance_application,
                            hbx_id: '111000223',
                            family_id: family2.id,
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
                            assistance_year: current_year,
                            full_medicaid_determination: true)
        end
        let!(:applicant2) do
          FactoryBot.create(:financial_assistance_applicant,
                            person_hbx_id: family2.primary_applicant.person.hbx_id,
                            is_primary_applicant: true,
                            family_member_id: family2.primary_applicant.id,
                            first_name: family2.primary_applicant.first_name,
                            last_name: family2.primary_applicant.last_name,
                            dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                            application: application2,
                            is_applying_coverage: false)
        end
        let!(:application3) do
          FactoryBot.create(:financial_assistance_application,
                            hbx_id: '111000224',
                            family_id: family2.id,
                            is_renewal_authorized: false,
                            is_requesting_voter_registration_application_in_mail: true,
                            years_to_renew: 5,
                            medicaid_terms: true,
                            report_change_terms: true,
                            medicaid_insurance_collection_terms: true,
                            parent_living_out_of_home_terms: true,
                            attestation_terms: true,
                            submission_terms: true,
                            aasm_state: 'draft',
                            assistance_year: current_year,
                            full_medicaid_determination: true)
        end
        let!(:active_enrollment2) do
          FactoryBot.create(:hbx_enrollment,
                            family: family2,
                            kind: "individual",
                            coverage_kind: "health",
                            aasm_state: 'coverage_selected',
                            effective_on: effective_on,
                            hbx_enrollment_members: [
                              FactoryBot.build(:hbx_enrollment_member, applicant_id: family2.primary_applicant.id, eligibility_date: effective_on, coverage_start_on: effective_on, is_subscriber: true)
                            ])
        end


        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).and_call_original
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @result = subject.call(renewal_year: renewal_year)
        end

        it 'returns family ids with all determined apps irrespective of application eligibility' do
          expect(@result.success.count).to eq 2
          expect(@result.success).to include(family.id)
          expect(@result.success).to include(family2.id)
        end
      end
    end
  end
end
