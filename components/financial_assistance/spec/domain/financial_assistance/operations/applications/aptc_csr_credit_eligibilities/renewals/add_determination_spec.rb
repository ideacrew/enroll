# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::AddDetermination, dbclean: :after_each do
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
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
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
        expect(@result.success).to match(/Successfully published the payload for event:/)
      end

      context 'for Appplication' do
        it 'should update aasm_state' do
          expect(@application.aasm_state).to eq("determined")
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

        it 'should update yearly_expected_contribution' do
          expect(@ed.yearly_expected_contribution.to_f).to eq(1_672.20)
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
      end

      context 'for Applicant' do
        it 'should update is_ia_eligible' do
          expect(@applicant.is_ia_eligible).to eq(true)
        end

        it 'should set is_ia_eligible to false if is_ia_eligible is nil' do
          # Without recreating the application were trying to resubmit a determined application and cannot transition from determined to submitted
          application.destroy
          application = FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "submitted")
          ed = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
          ed.update_attributes!(hbx_assigned_id: '12345')
          FactoryBot.create(:financial_assistance_applicant,
                            eligibility_determination_id: ed.id,
                            person_hbx_id: '95',
                            is_primary_applicant: true,
                            first_name: 'Gerald',
                            last_name: 'Rivers',
                            dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                            application: application)
          dup_response_payload = response_payload.dup
          dup_response_payload[:tax_households].first[:tax_household_members].first[:product_eligibility_determination][:is_ia_eligible] = nil
          subject.call(dup_response_payload)
          application = ::FinancialAssistance::Application.by_hbx_id(dup_response_payload[:hbx_id]).first.reload
          applicant = application.eligibility_determinations.first.applicants.first
          expect(applicant.is_ia_eligible).to eq(false)
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

        it 'should update csr_percent_as_integer value' do
          expect(@applicant.csr_percent_as_integer).to eq(-1)
        end

        it 'should update csr_percent_as_integer value' do
          expect(@applicant.csr_eligibility_kind).to eq("csr_limited")
        end

        it 'should update is_gap_filling' do
          expect(@applicant.is_gap_filling).to eq(true)
        end

        context 'member_determinations' do
          before do
            ped = response_payload[:tax_households].first[:tax_household_members].first[:product_eligibility_determination]
            @payload_member_determinations = ped[:member_determinations]
          end

          it 'should create a single member_determination for each kind' do
            @payload_member_determinations.each do |payload_member_determination|
              member_determination = @applicant.member_determinations.select { |md| md.kind == payload_member_determination[:kind] }
              expect(member_determination.count).to eq(1)
            end
          end

          it 'should update member_determination value' do
            @payload_member_determinations.each do |payload_member_determination|
              member_determination = @applicant.member_determinations.detect { |md| md.kind == payload_member_determination[:kind] }
              expect(member_determination.criteria_met).to eq(payload_member_determination[:criteria_met])
              expect(member_determination.determination_reasons).to eq(payload_member_determination[:determination_reasons])
              expect(member_determination.eligibility_overrides).to eq(payload_member_determination[:eligibility_overrides])
            end
          end
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
        expect(@result.failure).to eq('Found 0 applications with given hbx_id: 999999')
      end
    end

    context 'more than one matching persistence applications' do
      include_context 'cms ME simple_scenarios test_case_d'
      let!(:application2) do
        FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: 'draft')
      end

      before do
        @result = subject.call(response_payload)
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq('Found 2 applications with given hbx_id: 200000126')
      end
    end
  end
end
