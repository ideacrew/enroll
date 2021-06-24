# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "submitted")
  end
  let!(:ed) do
    eli_d = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
    eli_d.update_attributes!(hbx_assigned_id: '12345')
    eli_d
  end
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      eligibility_determination_id: ed.id,
                      person_hbx_id: '95',
                      is_primary_applicant: true,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day),
                      application: application)
  end

  context 'success' do
    context 'cms_ME_simple_scenarios test_case_d' do
      include_context 'cms ME simple_scenarios test_case_d'

      before do
        @result = subject.call(response_payload)
        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
        @ed = @application.eligibility_determinations.first
        @applicant = @ed.applicants.first
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with a message' do
        expect(@result.success).to eq('Successfully updated Application object with Full Eligibility Determination')
      end

      context 'for Appplication' do
        it 'should update aasm_state' do
          expect(@application.aasm_state).to eq("determined")
        end

        it 'should update determination_http_status_code' do
          expect(@application.determination_http_status_code).to eq(200)
        end

        it 'should update integrated_case_id' do
          expect(@application.integrated_case_id).to eq(@app_entity.hbx_id)
        end

        it 'should update has_eligibility_response' do
          expect(@application.has_eligibility_response).to eq(true)
        end

        it 'should update eligibility_response_payload' do
          expect(@application.eligibility_response_payload).to eq(@app_entity.to_h.to_json)
        end
      end

      context 'for Eligibility Determination' do
        it 'should update max_aptc' do
          expect(@ed.max_aptc.to_f).to eq(496.0)
        end

        it 'should update is_eligibility_determined' do
          expect(@ed.is_eligibility_determined).to eq(true)
        end

        it 'should update source' do
          expect(@ed.source).to eq('Faa')
        end

        it 'should update effective_starting_on' do
          expect(@ed.effective_starting_on).to eq(Date.today.next_month.beginning_of_month)
        end

        it 'should update determined_at' do
          expect(@ed.determined_at).to eq(Date.today)
        end

        it 'should update aptc_csr_annual_household_income' do
          expect(@ed.aptc_csr_annual_household_income.to_f).to eq(16_000.0)
        end

        it 'should update csr_annual_income_limit' do
          expect(@ed.csr_annual_income_limit.to_f).to eq(142_912_000.0)
        end

        it 'should update csr_percent_as_integer value' do
          expect(@ed.csr_percent_as_integer).to eq(94)
        end
      end

      context 'for Applicant' do
        it 'should update is_ia_eligible' do
          expect(@applicant.is_ia_eligible).to eq(true)
        end

        it 'should update is_medicaid_chip_eligible' do
          expect(@applicant.is_medicaid_chip_eligible).to eq(false)
        end

        it 'should update is_non_magi_medicaid_eligible' do
          expect(@applicant.is_non_magi_medicaid_eligible).to eq(false)
        end

        it 'should update is_eligible_for_non_magi_reasons' do
          expect(@applicant.is_eligible_for_non_magi_reasons).to eq(true)
        end

        it 'should update medicaid_household_size & not to be nil' do
          expect(@applicant.medicaid_household_size).not_to be_nil
          expect(@applicant.medicaid_household_size).to eq(0)
        end

        it 'should update magi_medicaid_category' do
          expect(@applicant.magi_medicaid_category).not_to be_nil
          expect(@applicant.magi_medicaid_category).to eq('none')
        end
      end
    end
  end

  context 'failure' do
    context 'invalid response payload' do
      before do
        @result = subject.call({ test: 'test' })
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end
    end

    context 'no matching persistence application' do
      include_context 'cms ME simple_scenarios test_case_d'

      before do
        response_payload.merge!({ hbx_id: '999999' })
        @result = subject.call(response_payload)
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq('Could not find application with given hbx_id: 999999')
      end
    end
  end
end
