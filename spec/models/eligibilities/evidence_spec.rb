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
    context '.extend_due_on' do
      before do
        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
        applicant.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:new_due_date) do
        applicant.schedule_verification_due_on + 30.days
      end

      it 'should update due date' do
        evidence = applicant.income_evidence

        expect(evidence.due_on).to be_nil
        expect(evidence.verification_histories).to be_empty

        output = evidence.extend_due_on(30.days, 'system')
        evidence.reload

        expect(output).to be_truthy
        expect(evidence.due_on).to eq new_due_date
        expect(evidence.verification_histories).to be_present

        history = evidence.verification_histories.first
        expect(history.action).to eq 'extend_due_date'
        expect(history.update_reason).to eq "Extended due date to #{evidence.due_on.strftime('%m/%d/%Y')}"
        expect(history.updated_by).to eq 'system'
      end

      it 'should update default due date for 30 days' do
        evidence = applicant.income_evidence
        expect(evidence.extend_due_on).to be_truthy
      end
    end

    context '.request_determination' do
      before do
        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
        applicant.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:updated_by) { '12345' }
      let(:update_reason) { "Requested Hub for verification" }
      let(:action) { 'request_hub' }
      let(:event) { double(success?: true, value!: double(publish: true)) }

      it 'should update due date' do
        evidence = applicant.esi_evidence

        evidence.stub(:construct_payload) { {} }
        evidence.stub(:event) { event }
        evidence.stub(:generate_evidence_updated_event) { true }

        expect(evidence.verification_histories).to be_empty

        result = evidence.request_determination(action, update_reason, updated_by)
        evidence.reload

        expect(result).to be_truthy
        expect(evidence.verification_histories).to be_present

        history = evidence.verification_histories.first
        expect(history.action).to eq action
        expect(history.update_reason).to eq update_reason
        expect(history.updated_by).to eq updated_by
      end
    end
  end
end
