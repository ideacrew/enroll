# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/ifsv/test_ifsv_eligibility_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Ifsv::H9t::IfsvEligibilityDetermination, dbclean: :after_each do
  include_context 'FDSH IFSV sample response'

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined")
  end

  let!(:ed) do
    eli_d = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
    eli_d.update_attributes!(hbx_assigned_id: '12345')
    eli_d
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      :with_income_evidence,
                      eligibility_determination_id: ed.id,
                      person_hbx_id: '1629165429385938',
                      is_primary_applicant: true,
                      first_name: 'Income',
                      last_name: 'evidence',
                      ssn: "111111111",
                      dob: Date.new(1988, 11, 11),
                      application: application)
  end

  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      eligibility_determination_id: ed.id,
                      person_hbx_id: '1629165429385939',
                      is_primary_applicant: true,
                      first_name: 'Non Income',
                      last_name: 'evidence',
                      ssn: "222222222",
                      dob: Date.new(1989, 11, 11),
                      application: application)
  end

  context 'success' do
    context 'FTI Ifsv eligible response' do
      before do
        @applicant = application.applicants.first
        @result = subject.call(payload: response_payload)

        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should update applicant verification' do
        @applicant.reload
        income_evidence = @applicant.income_evidence
        expect(income_evidence.verified?).to be_truthy
        expect(income_evidence.verification_outstanding).to be_falsey
        expect(income_evidence.due_on).to be_blank
        expect(income_evidence.is_satisfied).to eq true
        expect(income_evidence.request_results.present?).to eq true
        expect(@result.success).to eq('Successfully updated Applicant with evidence')
      end
    end

    context "applicant without evidence" do
      it 'should log an error if no income evidence present for an applicant' do
        log_message = "Income Evidence Not Found for applicant with person_hbx_id: 1629165429385939 in application with hbx_id: 200000126"
        expect(Rails.logger).to receive(:error).at_least(:once).with(log_message)
        subject.call(payload: response_payload)
      end
    end

    context 'FTI Ifsv ineligible response' do
      before do
        @applicant = application.applicants.first
        @result = subject.call(payload: response_payload_2)

        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload_2[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload_2).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should update applicant verification' do
        @applicant.reload
        income_evidence = @applicant.income_evidence
        expect(income_evidence.outstanding?).to be_falsey
        expect(income_evidence.verification_outstanding).to be_falsey
        expect(income_evidence.negative_response_received?).to be_truthy
        expect(income_evidence.is_satisfied).to eq false
        expect(income_evidence.request_results.present?).to eq true
        expect(@result.success).to eq('Successfully updated Applicant with evidence')
      end
    end
  end
end
