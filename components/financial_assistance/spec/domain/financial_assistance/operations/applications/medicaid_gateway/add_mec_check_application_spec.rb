# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_local_mec_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckApplication, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined")
  end
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      eligibility_determination_id: nil,
                      person_hbx_id: '1629165429385938',
                      is_primary_applicant: true,
                      first_name: 'aces',
                      last_name: 'evidence',
                      ssn: "518124854",
                      dob: Date.new(1988, 11, 11),
                      application: application)
  end

  context 'success' do
    context 'ACES MEC Check' do
      include_context 'ACES MEC Check sample response'

      before do
        @applicant = application.applicants.first
        @applicant.build_local_mec_evidence(key: :local_mec, title: "Local MEC")
        @applicant.save
        @result = subject.call(response_payload)

        @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should update applicant verification' do
        @applicant.reload
        expect(@applicant.local_mec_evidence.aasm_state).to eq "verified"
        expect(@applicant.local_mec_evidence.request_results.present?).to eq true
        expect(@result.success).to eq('Successfully updated Applicant with evidences and verifications')
      end
    end
  end
end