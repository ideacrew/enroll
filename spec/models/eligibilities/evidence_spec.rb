# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe ::Eligibilities::Evidence, type: :model, dbclean: :after_each do
  let!(:application) do
    FactoryBot.create(
      :application,
      family_id: BSON::ObjectId.new,
      aasm_state: 'submitted',
      assistance_year: TimeKeeper.date_of_record.year,
      effective_date: Date.today
    )
  end

  let!(:applicant) do
    FactoryBot.create(
      :applicant,
      application: application,
      dob: Date.today - 40.years,
      is_primary_applicant: true,
      family_member_id: BSON::ObjectId.new
    )
  end

  let(:income) do
    income = FactoryBot.build(:financial_assistance_income)
    applicant.incomes << income
  end

  describe 'Evidences present the applicant' do
    let(:esi_evidence) do
      applicant.create_esi_evidence(
        key: :esi_mec,
        title: 'Esi',
        aasm_state: 'pending',
        due_on: nil,
        verification_outstanding: false,
        is_satisfied: true
      )
    end

    let(:income_evidence) do
      applicant.create_income_evidence(
        key: :income,
        title: 'Income',
        aasm_state: 'pending',
        due_on: nil,
        verification_outstanding: false,
        is_satisfied: true
      )
    end

    let(:updated_by) { 'admin' }
    let(:update_reason) { "Requested Hub for verification" }
    let(:action) { 'request_hub' }

    context '.extend_due_on' do
      let(:new_due_date) do
        applicant.schedule_verification_due_on + 30.days
      end

      it 'should update due date' do
        expect(income_evidence.due_on).to be_nil
        expect(income_evidence.verification_histories).to be_empty

        output = income_evidence.extend_due_on(30.days, 'system')
        income_evidence.reload

        expect(output).to be_truthy
        expect(income_evidence.due_on).to eq new_due_date
        expect(income_evidence.verification_histories).to be_present

        history = income_evidence.verification_histories.first
        expect(history.action).to eq 'extend_due_date'
        expect(history.update_reason).to eq "Extended due date to #{income_evidence.due_on.strftime('%m/%d/%Y')}"
        expect(history.updated_by).to eq 'system'
      end

      it 'should update default due date for 30 days' do
        expect(income_evidence.extend_due_on).to be_truthy
      end
    end

    context '.request_determination for income evidence' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      end

      let(:evidence_verification_request) { instance_double(Operations::Fdsh::RequestEvidenceDetermination) }

      context 'with no errors' do
        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Success({}))
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(evidence_verification_request)
        end

        it 'should return success' do
          result = income_evidence.request_determination(action, update_reason, updated_by)
          income_evidence.reload

          expect(result).to be_truthy
          expect(income_evidence.verification_histories).to be_present

          history = income_evidence.verification_histories.first
          expect(history.action).to eq action
          expect(history.update_reason).to eq update_reason
          expect(history.updated_by).to eq updated_by
        end
      end

      context 'builds and publishes with errors' do
        let(:failed_action) { 'Hub Request Failed' }
        let(:failed_updated_by) { 'system' }
        let(:failed_update_reason) { "Invalid SSN" }

        let(:person) { FactoryBot.create(:person, :with_consumer_role) }
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Failure(failed_update_reason))
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(evidence_verification_request)

          family_member_id = family.family_members[0].id
          applicant.update(family_member_id: family_member_id)
          application.update(family_id: family.id)
        end

        context 'with an applicant without an active enrollment' do
          it 'should change evidence aasm_state to negative_response_received' do
            result = income_evidence.request_determination(action, update_reason, updated_by)
            income_evidence.reload

            expect(result).to be_falsey
            expect(income_evidence.aasm_state).to eq('negative_response_received')
            expect(income_evidence.verification_histories).to be_present

            admin_call_history = income_evidence.verification_histories.first
            expect(admin_call_history.action).to eq action
            expect(admin_call_history.update_reason).to eq update_reason
            expect(admin_call_history.updated_by).to eq updated_by

            failure_history = income_evidence.verification_histories.last
            expect(failure_history.action).to eq failed_action
            expect(failure_history.update_reason).to include(failed_update_reason)
            expect(failure_history.updated_by).to eq(failed_updated_by)
          end
        end

        context 'with an applicant who has an active enrollment' do
          let!(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                              family: family, enrollment_members: [family.primary_applicant],
                              aasm_state: 'coverage_selected', kind: 'individual')
          end

          before do
            family_member_id = family.family_members[0].id
            applicant.update(family_member_id: family_member_id)
            application.update(family_id: family.id)
          end

          context 'and not using aptc or valid csr' do
            before do
              # csr_variant_id "01" is not one of the valid csr codes to change aasm_state
              hbx_enrollment.product.update(csr_variant_id: '01')
            end

            it 'should change evidence aasm_state to negative_response_received' do
              result = income_evidence.request_determination(action, update_reason, updated_by)
              income_evidence.reload

              expect(result).to be_falsey
              expect(income_evidence.aasm_state).to eq('negative_response_received')
              expect(income_evidence.verification_histories).to be_present

              admin_call_history = income_evidence.verification_histories.first
              expect(admin_call_history.action).to eq action
              expect(admin_call_history.update_reason).to eq update_reason
              expect(admin_call_history.updated_by).to eq updated_by

              failure_history = income_evidence.verification_histories.last
              expect(failure_history.action).to eq failed_action
              expect(failure_history.update_reason).to include(failed_update_reason)
              expect(failure_history.updated_by).to eq(failed_updated_by)
            end
          end

          context 'and using aptc' do
            before do
              hbx_enrollment.update(applied_aptc_amount: 720)
              # csr_variant_id "01" is not one of the valid csr codes to change aasm_state
              hbx_enrollment.product.update(csr_variant_id: '01')
            end

            it 'should change evidence aasm_state to outstanding' do
              result = income_evidence.request_determination(action, update_reason, updated_by)
              income_evidence.reload

              expect(result).to be_falsey
              expect(income_evidence.aasm_state).to eq('outstanding')
              expect(income_evidence.verification_histories.size).to eq(2)
            end
          end

          context 'and using csr' do
            it 'should change evidence aasm_state to outstanding' do
              result = income_evidence.request_determination(action, update_reason, updated_by)
              income_evidence.reload

              expect(result).to be_falsey
              expect(income_evidence.aasm_state).to eq('outstanding')
              expect(income_evidence.verification_histories).to be_present
            end
          end
        end
      end
    end

    context 'payload_format' do
      let(:non_esi_evidence) do
        applicant.create_esi_evidence(
          key: :non_esi_mec,
          title: 'Non Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:esi_evidence) do
        applicant.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:income_evidence) do
        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      context 'non_esi_mec' do
        it 'should return payload format as json when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:non_esi_h31).and_return(true)
          allow(EnrollRegistry[:non_esi_h31].setting(:payload_format)).to receive(:item).and_return('json')
          expect(non_esi_evidence.payload_format).to eq({:non_esi_payload_format => 'json'})
        end

        it 'should return payload format as xml when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:non_esi_h31).and_return(true)
          allow(EnrollRegistry[:non_esi_h31].setting(:payload_format)).to receive(:item).and_return('xml')
          expect(non_esi_evidence.payload_format).to eq({:non_esi_payload_format => 'xml'})
        end
      end

      context 'esi_mec' do
        it 'should return payload format as json when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:esi_mec).and_return(true)
          allow(EnrollRegistry[:esi_mec].setting(:payload_format)).to receive(:item).and_return('json')
          expect(esi_evidence.payload_format).to eq({:esi_mec_payload_format => 'json'})
        end

        it 'should return payload format as xml when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:esi_mec).and_return(true)
          allow(EnrollRegistry[:esi_mec].setting(:payload_format)).to receive(:item).and_return('xml')
          expect(esi_evidence.payload_format).to eq({:esi_mec_payload_format => 'xml'})
        end
      end

      context 'ifsv' do
        it 'should return payload format as json when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ifsv).and_return(true)
          allow(EnrollRegistry[:ifsv].setting(:payload_format)).to receive(:item).and_return('json')
          expect(income_evidence.payload_format).to eq({:ifsv_payload_format => 'json'})
        end

        it 'should return payload format as xml when it is set' do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ifsv).and_return(true)
          allow(EnrollRegistry[:ifsv].setting(:payload_format)).to receive(:item).and_return('xml')
          expect(income_evidence.payload_format).to eq({:ifsv_payload_format => 'xml'})
        end
      end
    end

    context '.request_determination for esi mec evidence' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      end

      let(:evidence_verification_request) { instance_double(Operations::Fdsh::RequestEvidenceDetermination) }

      context 'with no errors' do
        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Success({}))
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(evidence_verification_request)
          esi_evidence.update_attributes!(aasm_state: 'unverified')
          income_evidence.update_attributes!(aasm_state: 'unverified')
          @result = esi_evidence.request_determination(action, update_reason, updated_by)
          esi_evidence.reload
        end

        it 'should return true' do
          expect(@result).to be_truthy
        end

        it 'should change esi evidence aasm_state to pending' do
          expect(esi_evidence).to have_state(:pending)
        end

        it 'should not change income evidence aasm_state to unverified' do
          expect(income_evidence).to have_state(:unverified)
        end

        it 'should create verification history for the requested call' do
          history = esi_evidence.verification_histories.first
          expect(history.action).to eq action
          expect(history.update_reason).to eq update_reason
          expect(history.updated_by).to eq updated_by
        end
      end

      context 'builds and publishes with errors' do
        let(:failed_action) { 'Hub Request Failed' }
        let(:failed_updated_by) { 'system' }
        let(:failed_update_reason) { "Invalid SSN" }

        let(:person) { FactoryBot.create(:person, :with_consumer_role) }
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Failure(failed_update_reason))
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(evidence_verification_request)

          family_member_id = family.family_members[0].id
          applicant.update(family_member_id: family_member_id)
          application.update(family_id: family.id)
        end

        context 'with an applicant without an active enrollment' do
          before do
            esi_evidence.update_attributes!(aasm_state: 'unverified')
            income_evidence.update_attributes!(aasm_state: 'unverified')
            @result = esi_evidence.request_determination(action, update_reason, updated_by)
            esi_evidence.reload
          end

          it 'should return false' do
            expect(@result).to be_falsey
          end

          it 'should change esi evidence aasm_state to attested' do
            expect(esi_evidence).to have_state(:attested)
          end

          it 'should not change income evidence aasm_state to attested' do
            expect(income_evidence).not_to have_state(:attested)
          end

          it 'should create history for requested call' do
            admin_call_history = esi_evidence.verification_histories.first
            expect(admin_call_history.action).to eq action
            expect(admin_call_history.update_reason).to eq update_reason
            expect(admin_call_history.updated_by).to eq updated_by
          end

          it 'should create history for failed publish' do
            failure_history = esi_evidence.verification_histories.last
            expect(failure_history.action).to eq failed_action
            expect(failure_history.update_reason).to include(failed_update_reason)
            expect(failure_history.updated_by).to eq(failed_updated_by)
          end
        end

        context 'with an applicant who has an active enrollment' do
          let!(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                              family: family, enrollment_members: [family.primary_applicant],
                              aasm_state: 'coverage_selected', kind: 'individual')
          end

          context 'and not using aptc or valid csr' do
            before do
              # csr_variant_id "01" is not one of the valid csr codes to change aasm_state
              hbx_enrollment.product.update(csr_variant_id: '01')
              esi_evidence.update_attributes!(aasm_state: 'unverified')
              @result = esi_evidence.request_determination(action, update_reason, updated_by)
              esi_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_falsey
            end

            it 'should change evidence aasm_state to attested' do
              expect(esi_evidence).to have_state(:attested)
            end

            it 'should create history for requested call' do
              admin_call_history = esi_evidence.verification_histories.first
              expect(admin_call_history.action).to eq action
              expect(admin_call_history.update_reason).to eq update_reason
              expect(admin_call_history.updated_by).to eq updated_by
            end

            it 'should create history for failed publish' do
              failure_history = esi_evidence.verification_histories.last
              expect(failure_history.action).to eq failed_action
              expect(failure_history.update_reason).to include(failed_update_reason)
              expect(failure_history.updated_by).to eq(failed_updated_by)
            end
          end

          context 'and using aptc' do
            before do
              hbx_enrollment.update(applied_aptc_amount: 720)
              esi_evidence.update_attributes!(aasm_state: 'unverified')
              @result = esi_evidence.request_determination(action, update_reason, updated_by)
              esi_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_falsey
            end

            it 'should change evidence aasm_state to attested' do
              expect(esi_evidence).to have_state(:attested)
            end

            it 'should create history for requested call' do
              admin_call_history = esi_evidence.verification_histories.first
              expect(admin_call_history.action).to eq action
              expect(admin_call_history.update_reason).to eq update_reason
              expect(admin_call_history.updated_by).to eq updated_by
            end

            it 'should create history for failed publish' do
              failure_history = esi_evidence.verification_histories.last
              expect(failure_history.action).to eq failed_action
              expect(failure_history.update_reason).to include(failed_update_reason)
              expect(failure_history.updated_by).to eq(failed_updated_by)
            end
          end
        end
      end
    end

    context 'when applicant_1 is valid and applicant_2 is invalid' do
      include_context "valid cv3 application setup"
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      end
      let(:person2) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }
      let!(:applicant2) do
        applicant = FactoryBot.create(:financial_assistance_applicant,
                                      application: application,
                                      is_primary_applicant: false,
                                      ssn: '999001234',
                                      dob: Date.today - 30.years,
                                      first_name: person2.first_name,
                                      last_name: person2.last_name,
                                      gender: person2.gender,
                                      person_hbx_id: person2.hbx_id,
                                      family_member_id: family_member2.id)
        applicant
      end

      let(:applicant_2_esi_evidence) do
        applicant2.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:applicant_1_esi_evidence) { esi_evidence}
      let(:applicant_1_income_evidence) { income_evidence}
      let(:applicant_2_income_evidence) do
        applicant2.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      context 'for esi evidence call hub' do
        context 'builds and publishes with errors' do
          let(:failed_action) { 'Hub Request Failed' }
          let(:failed_updated_by) { 'system' }
          let(:failed_update_reason) { "Invalid SSN" }

          let(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          before do
            family_member_id = family.family_members[0].id
            applicant.update(family_member_id: family_member_id)
            application.update(family_id: family.id)
          end

          context 'when hub call made for applicant 2' do
            before do
              @result = applicant_2_esi_evidence.request_determination(action, update_reason, updated_by)
              applicant_2_esi_evidence.reload
              applicant_1_esi_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_falsey
            end

            it 'should change applicant_2 esi evidence aasm_state to attested' do
              expect(applicant_2_esi_evidence).to have_state(:attested)
            end

            it 'should not change applicant_1 esi evidence aasm_state' do
              expect(applicant_1_esi_evidence).to have_state(:pending)
            end

            context 'for applicant_2' do
              it 'should create history for requested call' do
                admin_call_history = applicant_2_esi_evidence.verification_histories.first
                expect(admin_call_history.action).to eq action
                expect(admin_call_history.update_reason).to eq update_reason
                expect(admin_call_history.updated_by).to eq updated_by
              end

              it 'should create history for failed publish' do
                failure_history = applicant_2_esi_evidence.verification_histories.last
                expect(failure_history.action).to eq failed_action
                expect(failure_history.update_reason).to include(failed_update_reason)
                expect(failure_history.updated_by).to eq(failed_updated_by)
              end
            end

            context 'for applicant_1' do
              it 'should not create applicant_1 history for applicant_2 requested call' do
                admin_call_history = applicant_1_esi_evidence.verification_histories.first
                expect(admin_call_history.nil?).to be_truthy
              end
            end
          end

          context 'when hub call made for applicant 1' do
            before do
              @result = applicant_1_esi_evidence.request_determination(action, update_reason, updated_by)
              applicant_2_esi_evidence.reload
              applicant_1_esi_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_truthy
            end

            it 'should not change applicant_2 esi evidence aasm_state to attested' do
              expect(applicant_2_esi_evidence).to have_state(:pending)
            end

            it 'should not change applicant_1 evidence state even when applicant_2 is invalid' do
              expect(applicant_1_esi_evidence).to have_state(:pending)
            end

            context 'for applicant_1' do
              it 'should create history only for requested call' do
                admin_call_histories = applicant_1_esi_evidence.verification_histories
                expect(admin_call_histories.size).to eq(1)
              end

              it 'should create success history for requested call' do
                admin_call_history = applicant_1_esi_evidence.verification_histories.first
                expect(admin_call_history.action).to eq action
                expect(admin_call_history.update_reason).to eq update_reason
                expect(admin_call_history.updated_by).to eq updated_by
              end
            end

            context 'for applicant_2' do
              it 'should not create applicant_2 history for applicant_1 requested call' do
                admin_call_history = applicant_2_esi_evidence.verification_histories.first
                expect(admin_call_history.nil?).to be_truthy
              end
            end
          end
        end
      end

      context 'for income evidence call hub' do
        context 'builds and publishes with errors' do
          let(:failed_action) { 'Hub Request Failed' }
          let(:failed_updated_by) { 'system' }
          let(:failed_update_reason) { "Invalid SSN" }

          let(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          before do
            family_member_id = family.family_members[0].id
            applicant.update(family_member_id: family_member_id)
            application.update(family_id: family.id)
          end

          context 'when hub call made for applicant 2' do
            before do
              @result = applicant_2_income_evidence.request_determination(action, update_reason, updated_by)
              applicant_2_income_evidence.reload
              applicant_1_income_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_falsey
            end

            it 'should change applicant_2 income evidence aasm_state to negative_response_received' do
              expect(applicant_2_income_evidence).to have_state(:negative_response_received)
            end

            it 'should not change income evidence aasm_state' do
              expect(applicant_1_income_evidence).to have_state(:pending)
            end

            context 'for applicant_2' do
              it 'should create history for requested call' do
                admin_call_history = applicant_2_income_evidence.verification_histories.first
                expect(admin_call_history.action).to eq action
                expect(admin_call_history.update_reason).to eq update_reason
                expect(admin_call_history.updated_by).to eq updated_by
              end

              it 'should create history for failed publish' do
                failure_history = applicant_2_income_evidence.verification_histories.last
                expect(failure_history.action).to eq failed_action
                expect(failure_history.update_reason).to include(failed_update_reason)
                expect(failure_history.updated_by).to eq(failed_updated_by)
              end
            end

            context 'for applicant_1' do
              it 'should not create applicant_1 history for applicant_2 requested call' do
                admin_call_history = applicant_1_income_evidence.verification_histories.first
                expect(admin_call_history.nil?).to be_truthy
              end
            end
          end

          context 'when hub call made for applicant 1' do
            before do
              @result = applicant_1_income_evidence.request_determination(action, update_reason, updated_by)
              applicant_2_income_evidence.reload
              applicant_1_income_evidence.reload
            end

            it 'should return false' do
              expect(@result).to be_falsey
            end

            it 'should not change applicant_2 income evidence aasm_state to attested' do
              expect(applicant_2_income_evidence).to have_state(:pending)
            end

            it 'should change applicant_1 evidence state' do
              expect(applicant_1_income_evidence).to have_state(:negative_response_received)
            end

            context 'for applicant_1' do
              it 'should create history for requested call' do
                admin_call_history = applicant_1_income_evidence.verification_histories.first
                expect(admin_call_history.action).to eq action
                expect(admin_call_history.update_reason).to eq update_reason
                expect(admin_call_history.updated_by).to eq updated_by
              end

              it 'should create history for failed publish' do
                failure_history = applicant_1_income_evidence.verification_histories.last
                expect(failure_history.action).to eq failed_action
                expect(failure_history.update_reason).to include(failed_update_reason)
                expect(failure_history.updated_by).to eq(failed_updated_by)
              end
            end

            context 'for applicant_2' do
              it 'should not create applicant_2 history for applicant_1 requested call' do
                admin_call_history = applicant_2_income_evidence.verification_histories.first
                expect(admin_call_history.nil?).to be_truthy
              end
            end
          end
        end
      end
    end

    context 'reject' do
      before do
        income_evidence.move_to_rejected!
        income_evidence.reload
      end

      shared_examples_for 'transition to rejected' do |initial_state|
        let(:aasm_state) { initial_state }

        it 'should transition to rejected' do
          expect(income_evidence.aasm_state).to eq 'rejected'
        end

        it 'should have event on workflow state transistions' do
          workflow_st = income_evidence.workflow_state_transitions.last
          expect(workflow_st.event).to eq 'move_to_rejected!'
        end
      end

      it_behaves_like "transition to rejected", 'pending'
      it_behaves_like "transition to rejected", 'review'
      it_behaves_like "transition to rejected", 'attested'
      it_behaves_like "transition to rejected", 'verified'
      it_behaves_like "transition to rejected", 'outstanding'
    end
  end

  describe 'clone_embedded_documents' do
    let!(:income_evidence) do
      applicant.create_income_evidence(key: :income,
                                       title: 'Income',
                                       aasm_state: 'pending',
                                       due_on: Date.today,
                                       verification_outstanding: true,
                                       is_satisfied: false)
    end

    let!(:application2) do
      FactoryBot.create(:application, family_id: application.family_id, aasm_state: 'draft',
                                      assistance_year: TimeKeeper.date_of_record.year, effective_date: Date.today)
    end

    let!(:applicant2) do
      FactoryBot.create(:applicant, application: application, dob: Date.today - 40.years,
                                    is_primary_applicant: true, family_member_id: applicant.family_member_id)
    end

    let!(:income_evidence2) do
      applicant2.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'pending',
                                        due_on: Date.today,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end

    before do
      create_embedded_docs_for_evidence(income_evidence)
      income_evidence.verification_histories.first.update_attributes!(date_of_action: TimeKeeper.date_of_record - 1.day)
      income_evidence.request_results.first.update_attributes!(date_of_action: TimeKeeper.date_of_record - 1.day)
      income_evidence.clone_embedded_documents(income_evidence2)
      @new_verification_history = income_evidence.verification_histories.first
      @new_request_result = income_evidence.request_results.first
      @new_wfst = income_evidence.workflow_state_transitions.first
      @new_document = income_evidence.documents.first
    end

    it 'should clone verification_history' do
      expect(income_evidence.verification_histories).not_to be_empty
      expect(@new_verification_history.created_at).not_to be_nil
      expect(@new_verification_history.updated_at).not_to be_nil
    end

    it 'should clone request_result' do
      expect(income_evidence.request_results).not_to be_empty
      expect(@new_request_result.created_at).not_to be_nil
      expect(@new_request_result.updated_at).not_to be_nil
    end

    it 'should clone workflow_state_transition' do
      expect(income_evidence.workflow_state_transitions).not_to be_empty
      expect(@new_wfst.created_at).not_to be_nil
      expect(@new_wfst.updated_at).not_to be_nil
    end

    it 'should clone documents' do
      expect(income_evidence.documents).not_to be_empty
      expect(@new_document.created_at).not_to be_nil
      expect(@new_document.updated_at).not_to be_nil
    end

    it 'should copy the date_of_action of the copied document' do
      income_evidence2.verification_histories.first.save
      expect(income_evidence.verification_histories.first.date_of_action).to eql(income_evidence2.verification_histories.first.date_of_action)
    end

    it 'should copy the date_of_action of the request result' do
      income_evidence2.request_results.first.save
      expect(income_evidence.request_results.first.date_of_action).to eql(income_evidence2.request_results.first.date_of_action)
    end
  end

  context "verification reasons" do
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :me
      it "should have crm document system as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
        expect(::Eligibilities::Evidence::VERIFY_REASONS).to include("CRM Document Management System")
        expect(EnrollRegistry[:verification_reasons].item).to include("CRM Document Management System")
      end
    end
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :dc
      it "should have salesforce as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
        expect(::Eligibilities::Evidence::VERIFY_REASONS).to include("Salesforce")
        expect(EnrollRegistry[:verification_reasons].item).to include("Salesforce")
      end
    end
  end

  context 'move_evidence_to_outstanding' do
    let(:income_evidence) do
      applicant.create_income_evidence(
        key: :income,
        title: 'Income',
        aasm_state: 'pending',
        due_on: nil,
        verification_outstanding: false,
        is_satisfied: true
      )
    end

    context "when evidence is not outstanding and due_on is nil" do
      it "should move income evidence to outstanding and set due_on" do
        verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
        income_evidence.move_evidence_to_outstanding
        income_evidence.reload
        expect(income_evidence.aasm_state).to eq "outstanding"
        expect(income_evidence.due_on).to eq TimeKeeper.date_of_record + verification_document_due
        expect(income_evidence.verification_outstanding).to eq true
        expect(income_evidence.is_satisfied).to eq false
      end
    end

    context "when evidence is outstanding and due_on already exists" do
      before do
        income_evidence.update_attributes(aasm_state: :outstanding, due_on: TimeKeeper.date_of_record)
      end

      it "should move income evidence to outstanding and set due_on" do
        income_evidence.move_evidence_to_outstanding
        income_evidence.reload
        expect(income_evidence.aasm_state).to eq "outstanding"
        expect(income_evidence.due_on).to eq TimeKeeper.date_of_record
      end
    end
  end
end

def create_embedded_docs_for_evidence(evidence)
  create_verification_history(evidence)
  create_request_result(evidence)
  create_workflow_state_transition(evidence)
  create_document(evidence)
end

def create_verification_history(evidence)
  evidence.verification_histories.create(action: 'verify', update_reason: 'Document in EnrollApp', updated_by: 'admin@user.com')
end

def create_request_result(evidence)
  evidence.request_results.create(result: 'verified', source: 'FDSH IFSV', raw_payload: 'raw_payload')
end

def create_workflow_state_transition(evidence)
  evidence.workflow_state_transitions.create(to_state: "approved", transition_at: TimeKeeper.date_of_record, reason: "met minimum criteria",
                                             comment: "consumer provided proper documentation", user_id: BSON::ObjectId.from_time(DateTime.now))
end

def create_document(evidence)
  evidence.documents.create(title: 'document.pdf', creator: 'mehl', subject: 'document.pdf', publisher: 'mehl', type: 'text', identifier: 'identifier', source: 'enroll_system', language: 'en')
end
