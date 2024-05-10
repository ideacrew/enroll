# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/ifsv/test_ifsv_eligibility_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::Ifsv::H9t::IfsvEligibilityDetermination, dbclean: :after_each do
  include_context 'FDSH IFSV sample response'

  before :all do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined", family_id: family.id)
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
                      family_member_id: family.primary_family_member.id,
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

  let(:enrollment) { nil }

  context 'success' do
    context 'FTI Ifsv eligible response' do
      let(:payload) { response_payload }
      before do
        enrollment
        @applicant = application.applicants.first
        @result = subject.call(payload: payload)

        @application = ::FinancialAssistance::Application.by_hbx_id(payload[:hbx_id]).first.reload
        @app_entity = ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).success
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

      context 'when is_ifsv_eligible is true' do
        let(:payload) do
          response_payload[:tax_households].each { |th| th[:is_ifsv_eligible] = true }
          response_payload
        end

        it 'should return success' do
          expect(@result).to be_success
        end

        it 'should return verified status' do
          @applicant.reload
          income_evidence = @applicant.income_evidence
          expect(income_evidence.verified?).to be_truthy
          expect(income_evidence.verification_outstanding).to be_falsey
        end
      end

      context 'when is_ifsv_eligible is false' do
        let(:payload) do
          response_payload[:tax_households].each { |th| th[:is_ifsv_eligible] = false }
          response_payload
        end

        context 'when not enrolled' do

          it 'should return success' do
            expect(@result).to be_success
          end

          it 'should return negative_response_received' do
            @applicant.reload
            income_evidence = @applicant.income_evidence
            expect(income_evidence.negative_response_received?).to be_truthy
            expect(income_evidence.verification_outstanding).to be_falsey
          end
        end

        context 'when enrolled' do
          let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }

          it 'should return success' do
            expect(@result).to be_success
          end

          context 'and income_evidence in state review' do
            context 'with aptc used' do
              let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_aptc_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }

              it 'returns review' do
                income_evidence = @applicant.income_evidence
                income_evidence.move_to_review
                subject.call(payload: response_payload)
                enrollment_member = enrollment.hbx_enrollment_members.first
                enrollment_member.person.update(hbx_id: '1629165429385938')
                income_evidence = @applicant.income_evidence
                expect(income_evidence.review?).to be_truthy
              end
            end
          end

          context 'and income_evidence in state rejected' do
            context 'with aptc used' do
              let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_aptc_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }

              it 'returns rejected' do
                income_evidence = @applicant.income_evidence
                @applicant.set_evidence_rejected(income_evidence)
                subject.call(payload: response_payload)
                enrollment_member = enrollment.hbx_enrollment_members.first
                enrollment_member.person.update(hbx_id: '1629165429385938')
                income_evidence = @applicant.income_evidence
                expect(income_evidence.rejected?).to be_truthy
              end
            end
          end

          context 'with aptc used' do

            let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_aptc_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }
            before(:each) do
              subject.call(payload: response_payload)
              enrollment_member = enrollment.hbx_enrollment_members.first
              enrollment_member.person.update(hbx_id: '1629165429385938')
              enrollment.reload
            end

            it 'returns outstanding' do
              subject.call(payload: response_payload)

              @applicant.reload
              income_evidence = @applicant.income_evidence
              expect(income_evidence.outstanding?).to be_truthy
              expect(income_evidence.verification_outstanding).to be_truthy
            end
          end

          context 'without aptc used' do
            let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }

            it 'returns negative_response_received' do
              enrollment.product.update(csr_variant_id: '01')
              enrollment.reload
              subject.call(payload: response_payload)

              @applicant.reload
              income_evidence = @applicant.income_evidence
              expect(income_evidence.negative_response_received?).to be_truthy
              expect(income_evidence.verification_outstanding).to be_falsey
            end
          end

          context 'with csr used' do
            let(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product, family: family, enrollment_members: family.family_members) }

            let!(:applicant) do
              FactoryBot.create(:financial_assistance_applicant,
                                :with_income_evidence,
                                csr_eligibility_kind: 'csr_87',
                                eligibility_determination_id: ed.id,
                                person_hbx_id: '1629165429385938',
                                is_primary_applicant: true,
                                first_name: 'Income',
                                last_name: 'evidence',
                                ssn: "111111111",
                                dob: Date.new(1988, 11, 11),
                                family_member_id: family.primary_family_member.id,
                                application: application)
            end

            it 'returns outstanding' do
              subject.call(payload: response_payload)

              @applicant.reload
              income_evidence = @applicant.income_evidence
              expect(income_evidence.outstanding?).to be_truthy
              expect(income_evidence.verification_outstanding).to be_truthy
            end
          end
        end
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
        expect(income_evidence.is_satisfied).to eq true
        expect(income_evidence.request_results.present?).to eq true
        expect(@result.success).to eq('Successfully updated Applicant with evidence')
      end
    end

    context 'when Retry with Ifsv ineligible response' do
      let(:income_evidence) { applicant.income_evidence }

      before do
        income_evidence.verification_histories.create(action: "retry")
        income_evidence.save
        subject.call(payload: response_payload_2)
        income_evidence.reload
      end

      it 'should not update income' do
        expect(income_evidence.pending?).to be_truthy
        expect(income_evidence.due_on).to eq nil
      end

      it 'should record the payload on the retry' do
        expect(income_evidence.request_results.count).to eq 1
      end
    end
  end
end
