# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/dummy/app/domain/operations/individual/open_enrollment_start_on"

RSpec.describe ::FinancialAssistance::Operations::Applications::Verifications::RequestApplicationDetermination, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let!(:person) { FactoryBot.create(:person, :with_ssn, hbx_id: "732020") }
  let!(:person_2) { FactoryBot.create(:person, :with_ssn, hbx_id: "732021") }
  let!(:person_3) { FactoryBot.create(:person, :with_ssn, hbx_id: "732022") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'determined', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  let!(:applicant) do
    FactoryBot.build(:financial_assistance_applicant,
                     :with_student_information,
                     :with_home_address,
                     :with_esi_evidence,
                     :with_non_esi_evidence,
                     :with_local_mec_evidence,
                     application: application,
                     is_primary_applicant: true,
                     ssn: '889984400',
                     dob: Date.new(1994,11,17),
                     first_name: person.first_name,
                     last_name: person.last_name,
                     gender: person.gender,
                     person_hbx_id: person.hbx_id,
                     eligibility_determination_id: eligibility_determination.id)
  end

  let!(:applicant_2) do
    FactoryBot.build(:financial_assistance_applicant,
                     :with_student_information,
                     :with_home_address,
                     :with_income_evidence,
                     :with_esi_evidence,
                     :with_non_esi_evidence,
                     :with_local_mec_evidence,
                     application: application,
                     is_primary_applicant: false,
                     ssn: '889984400',
                     dob: Date.new(1995,11,17),
                     first_name: person_2.first_name,
                     last_name: person_2.last_name,
                     gender: person_2.gender,
                     person_hbx_id: person_2.hbx_id,
                     eligibility_determination_id: eligibility_determination.id)
  end

  let!(:applicant_3) do
    FactoryBot.build(:financial_assistance_applicant,
                     :with_student_information,
                     :with_home_address,
                     :with_income_evidence,
                     :with_esi_evidence,
                     :with_non_esi_evidence,
                     :with_local_mec_evidence,
                     application: application,
                     is_primary_applicant: false,
                     ssn: '889984400',
                     dob: Date.new(2007,11,17),
                     first_name: person_3.first_name,
                     last_name: person_3.last_name,
                     gender: person_3.gender,
                     person_hbx_id: person_3.hbx_id,
                     eligibility_determination_id: eligibility_determination.id)
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
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)

    applicant.esi_evidence.update(aasm_state: 'pending')
    applicant_2.esi_evidence.update(aasm_state: 'pending')
    applicant_3.esi_evidence.update(aasm_state: 'pending')
    applicant.non_esi_evidence.update(aasm_state: 'pending')
    applicant_2.non_esi_evidence.update(aasm_state: 'pending')
    applicant_3.non_esi_evidence.update(aasm_state: 'pending')
    applicant.local_mec_evidence.update(aasm_state: 'pending')
    applicant_2.local_mec_evidence.update(aasm_state: 'pending')
    applicant_3.local_mec_evidence.update(aasm_state: 'pending')
  end

  context 'with valid application' do
    before do
      @result = subject.call(application)
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should return success with message' do
      expect(@result.success).to eq('Event published successfully')
    end
  end

  context 'with invalid application' do
    before do
      @result = subject.call("application_id")
    end

    it 'should return a failure with error message' do
      expect("Invalid Application object application_id, expected FinancialAssistance::Application")
    end
  end

  context 'elgibility validation' do

    context 'with an invalid applicant' do
      context 'on mec evidence' do
        before do
          applicant.update(ssn: '000348745')
          @result = subject.call(application)
        end

        it 'should be sucessful' do
          expect(@result).to be_success
        end

        it "should update invalid applicants' verification history" do
          evidence = applicant.esi_evidence
          expect(evidence.verification_histories.length).to eq 1
          expect(evidence.verification_histories.first.update_reason).to include "Invalid SSN"
        end

        it "should NOT modify valid applicants' verification histories" do
          evidence2 = applicant_2.esi_evidence
          evidence3 = applicant_3.esi_evidence
          expect(evidence2.verification_histories.length).to eq 0
          expect(evidence3.verification_histories.length).to eq 0
        end

        it 'should update the invalid applicants aasm_states to attested' do
          evidence = applicant.esi_evidence
          expect(evidence.aasm_state).to eq "attested"
        end
      end

      context 'on income evidence' do
        before do
          applicant.build_income_evidence(
            key: :income,
            title: 'Income',
            aasm_state: :pending,
            due_on: TimeKeeper.date_of_record,
            verification_outstanding: true,
            is_satisfied: false
          )
          applicant.update(ssn: '000348745')
          @result = subject.call(application)
        end

        it 'should fail' do
          expect(@result).to_not be_success
        end

        it "should update all applicants' verification histories" do
          evidence1 = applicant.income_evidence
          evidence2 = applicant_2.income_evidence
          evidence3 = applicant_3.income_evidence
          expect(evidence1.verification_histories.length).to eq 1
          expect(evidence2.verification_histories.length).to eq 1
          expect(evidence3.verification_histories.length).to eq 1
        end

        it 'should update the aasm_states to negative_response_received' do
          evidence1 = applicant.income_evidence
          evidence2 = applicant_2.income_evidence
          evidence3 = applicant_3.income_evidence
          expect(evidence1.aasm_state).to eq "negative_response_received"
          expect(evidence2.aasm_state).to eq "negative_response_received"
          expect(evidence3.aasm_state).to eq "negative_response_received"
        end
      end
    end

    context 'with ALL invalid applicants' do
      before do
        applicant.update(ssn: '000348745')
        applicant_2.update(ssn: '000348746')
        applicant_3.update(ssn: '000348747')
        @result = subject.call(application)
      end

      it 'should fail' do
        expect(@result).to_not be_success
      end
    end
  end
end
