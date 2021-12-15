# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/ifsv/test_ifsv_eligibility_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Ifsv::H9t::IfsvEligibilityDetermination, dbclean: :after_each do
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
                      eligibility_determination_id: ed.id,
                      person_hbx_id: '1629165429385938',
                      is_primary_applicant: true,
                      first_name: 'esi',
                      last_name: 'evidence',
                      ssn: "518124854",
                      dob: Date.new(1988, 11, 11),
                      application: application)
  end

  context 'success' do
    context 'FTI Ifsv eligible response' do
      include_context 'FDSH IFSV sample response'

      before do
        @applicant = application.applicants.first
        @applicant.build_income_evidence(key: :income, title: "Income", aasm_state: "attested")
        @applicant.save!
        @result = subject.call(payload: response_payload)

        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should update applicant verification' do
        @applicant.reload
        expect(@applicant.income_evidence.aasm_state).to eq "verified"
        expect(@result.success).to eq('Successfully updated Applicant with evidence')
      end
    end

    context 'FTI Ifsv ineligible response' do
      include_context 'FDSH IFSV sample response'

      before do
        @applicant = application.applicants.first
        @applicant.build_income_evidence(key: :income, title: "Income", aasm_state: "attested")
        @applicant.save!
        @result = subject.call(payload: response_payload_2)

        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should update applicant verification' do
        @applicant.reload
        expect(@applicant.income_evidence.aasm_state).to eq "outstanding"
        expect(@result.success).to eq('Successfully updated Applicant with evidence')
      end
    end
  end
end
