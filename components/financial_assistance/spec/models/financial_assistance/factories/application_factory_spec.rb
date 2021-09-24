# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::ApplicationFactory, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let!(:applicant2) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 10.years,
                      family_member_id: BSON::ObjectId.new)
  end

  context 'duplicate' do

    context 'Should not create relationships for duplicate/new application if there are no relationship for application.' do
      before do
        factory = described_class.new(application)
        @duplicate_application = factory.duplicate
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.count).to eq 0
      end
    end

    context 'Should create relationships for duplicate/new application with applicants from new application.' do
      before do
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant2.id, relative_id: applicant.id, kind: "child")
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant.id, relative_id: applicant2.id, kind: "parent")
        factory = described_class.new(application)
        @duplicate_application = factory.duplicate
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.pluck(:relative_id)).to eq @duplicate_application.applicants.pluck(:id)
      end
    end

    context 'for application' do
      context 'for determination_http_status_code, has_eligibility_response, eligibility_response_payload & eligibility_request_payload' do
        let(:mocked_params) do
          { determination_http_status_code: 200,
            has_eligibility_response: true,
            eligibility_response_payload: { hbx_id: application.hbx_id, us_state: 'DC' }.to_json,
            eligibility_request_payload: { hbx_id: application.hbx_id, us_state: 'DC' }.to_json,
            assistance_year: TimeKeeper.date_of_record.year,
            renewal_base_year: TimeKeeper.date_of_record.year }
        end

        before do
          application.update_attributes!(mocked_params)
          factory = described_class.new(application)
          @duplicate_application = factory.duplicate
        end

        it 'should not copy determination_http_status_code' do
          expect(@duplicate_application.determination_http_status_code).to be_nil
        end

        it 'should not copy has_eligibility_response' do
          expect(@duplicate_application.has_eligibility_response).not_to eq(true)
        end

        it 'should not copy eligibility_response_payload' do
          expect(@duplicate_application.eligibility_response_payload).to be_nil
        end

        it 'should not copy eligibility_request_payload' do
          expect(@duplicate_application.eligibility_request_payload).to be_nil
        end

        it 'should not copy renewal_base_year' do
          expect(@duplicate_application.renewal_base_year).to be_nil
        end
      end

      context 'for predecessor_id' do
        let(:predecessor_application) do
          FactoryBot.create(:application,
                            family_id: application.family_id,
                            aasm_state: "determined",
                            effective_date: TimeKeeper.date_of_record)
        end

        let(:mocked_params) { { predecessor_id: predecessor_application.id } }

        before do
          application.update_attributes!(mocked_params)
          factory = described_class.new(application)
          @duplicate_application = factory.duplicate
        end

        it 'should not copy predecessor_id' do
          expect(@duplicate_application.predecessor_id).to be_nil
        end
      end
    end

    context 'for applicant' do
      context 'for medicaid_household_size, magi_medicaid_category, magi_as_percentage_of_fpl,
               magi_medicaid_monthly_income_limit, magi_medicaid_monthly_household_income,
               is_without_assistance, is_ia_eligible, is_medicaid_chip_eligible,
               is_totally_ineligible, is_eligible_for_non_magi_reasons, is_non_magi_medicaid_eligible,
               csr_percent_as_integer & csr_eligibility_kind' do
        let(:mocked_params) do
          { medicaid_household_size: 1,
            magi_medicaid_category: 'residency',
            magi_as_percentage_of_fpl: 100,
            magi_medicaid_monthly_income_limit: 10_000.00,
            magi_medicaid_monthly_household_income: 5_000.00,
            is_without_assistance: true,
            is_ia_eligible: true,
            is_medicaid_chip_eligible: true,
            is_totally_ineligible: true,
            is_eligible_for_non_magi_reasons: true,
            is_non_magi_medicaid_eligible: true,
            csr_percent_as_integer: 94,
            csr_eligibility_kind: 'csr_94' }
        end

        before do
          applicant.update_attributes!(mocked_params)
          factory = described_class.new(application)
          duplicate_application = factory.duplicate
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not copy medicaid_household_size' do
          expect(@duplicate_applicant.medicaid_household_size).to be_nil
        end

        it 'should not copy magi_medicaid_category' do
          expect(@duplicate_applicant.magi_medicaid_category).to be_nil
        end

        it 'should not copy magi_as_percentage_of_fpl' do
          expect(@duplicate_applicant.magi_as_percentage_of_fpl).to be_zero
        end

        it 'should not copy magi_medicaid_monthly_income_limit' do
          expect(@duplicate_applicant.magi_medicaid_monthly_income_limit.to_f).to be_zero
        end

        it 'should not copy magi_medicaid_monthly_household_income' do
          expect(@duplicate_applicant.magi_medicaid_monthly_household_income).to be_zero
        end

        it 'should not copy is_without_assistance' do
          expect(@duplicate_applicant.is_without_assistance).not_to be_truthy
        end

        it 'should not copy is_ia_eligible' do
          expect(@duplicate_applicant.is_ia_eligible).not_to be_truthy
        end

        it 'should not copy is_medicaid_chip_eligible' do
          expect(@duplicate_applicant.is_medicaid_chip_eligible).not_to be_truthy
        end

        it 'should not copy is_totally_ineligible' do
          expect(@duplicate_applicant.is_totally_ineligible).not_to be_truthy
        end

        it 'should not copy is_eligible_for_non_magi_reasons' do
          expect(@duplicate_applicant.is_eligible_for_non_magi_reasons).not_to be_truthy
        end

        it 'should not copy is_non_magi_medicaid_eligible' do
          expect(@duplicate_applicant.is_non_magi_medicaid_eligible).not_to be_truthy
        end

        it 'should not copy csr_percent_as_integer' do
          expect(@duplicate_applicant.csr_percent_as_integer).not_to eq(mocked_params[:csr_percent_as_integer])
        end

        it 'should not copy csr_eligibility_kind' do
          expect(@duplicate_applicant.csr_eligibility_kind).not_to eq(mocked_params[:csr_eligibility_kind])
        end
      end

      context 'for net_annual_income' do
        let(:mocked_params) { { net_annual_income: 10_012.00 } }

        before do
          applicant.update_attributes!(mocked_params)
          factory = described_class.new(application)
          duplicate_application = factory.duplicate
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not copy net_annual_income' do
          expect(@duplicate_applicant.net_annual_income).to be_nil
        end
      end
    end
  end
end
