# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/esi/test_esi_mec_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Esi::H14::AddEsiMecDetermination, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined", family_id: family.id)
  end
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      eligibility_determination_id: nil,
                      person_hbx_id: '1629165429385938',
                      is_primary_applicant: true,
                      first_name: 'esi',
                      last_name: 'evidence',
                      ssn: "518124854",
                      dob: Date.new(1988, 11, 11),
                      family_member_id: family.primary_family_member.id,
                      application: application)
  end

  let(:enrollment) { nil }

  context 'success' do
    context 'FDSH ESI MEC' do
      include_context 'FDSH ESI MEC sample response'

      before do
        enrollment
        @applicant = application.applicants.first
        @applicant.build_esi_evidence(key: :esi_mec, title: "ESI MEC")
        @applicant.save!
        @result = subject.call(payload: payload)

        @application = ::FinancialAssistance::Application.by_hbx_id(payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).success
      end

      context 'when aasm_state is verified' do
        let(:payload) do
          response_payload[:applicants].each { |applicant| applicant[:esi_evidence][:aasm_state] = 'verified' }
          response_payload
        end

        it 'should return success' do
          expect(@result).to be_success
        end

        it 'should update applicant verification' do
          @applicant.reload
          expect(@applicant.esi_evidence.aasm_state).to eq "attested"
          expect(@applicant.esi_evidence.request_results.present?).to eq true
          expect(@result.success).to eq('Successfully updated Applicant with evidences and verifications')
        end
      end

      context 'when aasm_state is outstanding' do
        let(:payload) do
          response_payload[:applicants].each { |applicant| applicant[:esi_evidence][:aasm_state] = 'outstanding' }
          response_payload
        end

        context 'when not enrolled' do

          it 'should return success' do
            expect(@result).to be_success
          end

          it 'should update applicant verification' do
            @applicant.reload
            expect(@applicant.esi_evidence.aasm_state).to eq "negative_response_received"
            expect(@applicant.esi_evidence.request_results.present?).to eq true
            expect(@result.success).to eq('Successfully updated Applicant with evidences and verifications')
          end
        end

        context 'when enrolled' do
          let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, family: family, enrollment_members: family.family_members) }

          it 'should return success' do
            expect(@result).to be_success
          end

          it 'should update applicant verification' do
            @applicant.reload
            expect(@applicant.esi_evidence.aasm_state).to eq "outstanding"
            expect(@applicant.esi_evidence.request_results.present?).to eq true
            expect(@result.success).to eq('Successfully updated Applicant with evidences and verifications')
          end
        end
      end
    end
  end
end
