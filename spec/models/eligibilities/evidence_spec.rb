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

    context '.request_determination' do
      let(:updated_by) { '12345' }
      let(:update_reason) { "Requested Hub for verification" }
      let(:action) { 'request_hub' }
      let(:success_event) { double(success?: true, value!: double(publish: true)) }
      let(:failure_event) { double(success?: false, value!: double(publish: false)) }
      let(:failure_publish) { double(success?: true, value!: double(publish: false)) }
      let(:success_payload) { double(failure?: false, value!: {}) }

      before do
        esi_evidence.stub(:generate_evidence_updated_event) { true }
        esi_evidence.stub(:construct_payload) { success_payload }
      end

      it 'should not update due date' do
        esi_evidence.stub(:event) { failure_event }
        esi_evidence.request_determination(action, update_reason, updated_by)
        esi_evidence.reload
        expect(esi_evidence.verification_histories).to be_empty
      end

      it 'should update due date with history' do
        esi_evidence.stub(:event) { success_event }
        expect(esi_evidence.verification_histories).to be_empty
        result = esi_evidence.request_determination(action, update_reason, updated_by)
        esi_evidence.reload
        expect(result).to be_truthy
        expect(esi_evidence.verification_histories).to be_present

        history = esi_evidence.verification_histories.first
        expect(history.action).to eq action
        expect(history.update_reason).to eq update_reason
        expect(history.updated_by).to eq updated_by
      end

      it 'should not update due date with history' do
        esi_evidence.stub(:event) { failure_publish }
        expect(esi_evidence.verification_histories).to be_empty
        result = esi_evidence.request_determination(action, update_reason, updated_by)
        esi_evidence.reload
        expect(result).to be_falsey
        expect(esi_evidence.verification_histories).to be_present

        history = esi_evidence.verification_histories.first
        expect(history.action).to eq action
        expect(history.update_reason).to eq "Failed to request determination"
        expect(history.updated_by).to eq "system"
      end
    end

    context "construct_payload" do
      it 'should have failure history' do
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
        esi_evidence.construct_payload(application, "system")
        expect(esi_evidence.verification_histories.last.update_reason).to eq 'Failed to construct payload'
      end

      it 'should have failure history' do
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Success.new(application))
        allow(::AcaEntities::MagiMedicaid::Operations::InitializeApplication).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
        esi_evidence.construct_payload(application, "system")
        expect(esi_evidence.verification_histories.last.update_reason).to eq 'Failed to validate application'
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
