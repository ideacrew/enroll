# frozen_string_literal: true

require 'rails_helper'

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

    let(:updated_by) { 'admin' }
    let(:update_reason) { "Requested Hub for verification" }
    let(:action) { 'request_hub' }

    context '.request_determination' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)
      end

      let(:evidence_verification_request) { instance_double(Operations::Fdsh::EvidenceVerificationRequest) }

      context 'with no errors' do
        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Success({}))
          allow(Operations::Fdsh::EvidenceVerificationRequest).to receive(:new).and_return(evidence_verification_request)
        end

        it 'should return success' do
          result = income_evidence.request_determination(action, update_reason, updated_by)
          income_evidence.reload

          expect(result).to be_success
          expect(income_evidence.verification_histories).to be_present

          history = income_evidence.verification_histories.first
          expect(history.action).to eq action
          expect(history.update_reason).to eq update_reason
          expect(history.updated_by).to eq updated_by
        end
      end

      context 'builds and publishes with errors' do
        let(:failed_action) { 'Hub Request Failed' }
        let(:failed_updated_by) { 'System' }
        let(:failed_update_reason) { "Invalid SSN" }

        let(:person) { FactoryBot.create(:person, :with_consumer_role, ) }
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

        before do
          allow(evidence_verification_request).to receive(:call).and_return(Dry::Monads::Failure(failed_update_reason))
          allow(Operations::Fdsh::EvidenceVerificationRequest).to receive(:new).and_return(evidence_verification_request)

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
