# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AutoExtendIncomeEvidence, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
  let!(:person) { family.primary_person }
  let!(:application) do
    FactoryBot.create(:application,
                      family_id: family.id,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: family.family_members[0].id,
                      person_hbx_id: person.hbx_id,
                      addresses: [FactoryBot.build(:financial_assistance_address)])
  end

  let!(:applicant2) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 25.years,
                      is_primary_applicant: false,
                      family_member_id: family.family_members[1].id,
                      person_hbx_id: family.family_members[1].person.hbx_id,
                      addresses: [FactoryBot.build(:financial_assistance_address)])
  end

  let!(:applicant3) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 25.years,
                      is_primary_applicant: false,
                      family_member_id: family.family_members[2].id,
                      person_hbx_id: family.family_members[2].person.hbx_id,
                      addresses: [FactoryBot.build(:financial_assistance_address)])
  end

  let!(:income_evidence) do
    applicant.create_income_evidence(key: :income,
                                     title: 'Income',
                                     aasm_state: 'outstanding',
                                     due_on: TimeKeeper.date_of_record,
                                     verification_outstanding: true,
                                     is_satisfied: false)
  end

  let!(:income_evidence2) do
    applicant2.create_income_evidence(key: :income,
                                     title: 'Income',
                                     aasm_state: 'pending',
                                     due_on: TimeKeeper.date_of_record,
                                     verification_outstanding: true,
                                     is_satisfied: false)
  end

  let!(:income_evidence3) do
    applicant3.create_income_evidence(key: :income,
                                     title: 'Income',
                                     aasm_state: 'outstanding',
                                     due_on: TimeKeeper.date_of_record + 2.weeks,
                                     verification_outstanding: true,
                                     is_satisfied: false)
  end

  context 'success' do
    context 'with no params submitted' do
      before do
        @result = subject.call({})
        applicant.reload
      end

      it 'should return success' do
        expect(@result).to be_success
        expect(@result.value!.length).to eq(1)
        expect(@result.value!.include?(person.hbx_id)).to be_truthy
      end

      it 'should update the income evidence due on for the applicant' do
        expect(applicant.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record)
        expect(applicant.income_evidence.due_on).to eq(TimeKeeper.date_of_record + 65.days)
      end

      it 'should add a verification history recording the update' do
        history = applicant.income_evidence.verification_histories.last
        expect(history.action).to eq("auto_extend_due_date")
        expect(history.updated_by).to eq("system")
      end

      it 'should not update the applicant if the evidence is not in outstanding or rejected' do
        expect(applicant2.income_evidence.due_on).to eq(TimeKeeper.date_of_record)
        expect(applicant2.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record + 65.days)
      end

      it 'should not update the applicant if due on is not equal to the provided date' do
        expect(applicant3.income_evidence.due_on).to eq(TimeKeeper.date_of_record + 2.weeks)
        expect(applicant3.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record + 65.days)
      end

    end

    context 'previously auto extended' do
      before do
        income_evidence.verification_histories.create(action: 'auto_extend_due_date', update_reason: 'Auto extended due date', updated_by: 'system')
        @result = subject.call({})
      end

      it 'should return success' do
        expect(@result).to be_success
        expect(@result.value!.length).to eq(0)
        expect(@result.value!.include?(person.hbx_id)).to be_falsy
      end

    end

    context 'previously auto extended then transistion to attested or verified' do
      before do
        income_evidence.verification_histories.create(action: 'auto_extend_due_date', update_reason: 'Auto extended due date', updated_by: 'system')
        income_evidence.workflow_state_transitions.create(to_state: "verified", transition_at: TimeKeeper.date_of_record, reason: "met minimum criteria", comment: "consumer provided proper documentation",
                                                          user_id: BSON::ObjectId.from_time(DateTime.now))
        @result = subject.call({})
      end

      it 'should return success' do
        expect(@result).to be_success
        expect(@result.value!.length).to eq(1)
        expect(@result.value!.include?(person.hbx_id)).to be_truthy
      end
    end

    context 'with params given' do
      before do
        @result = subject.call({extend_by: 35, modified_by: 'admin@ideacrew.com'})
        applicant.reload
      end

      it 'should return success' do
        expect(@result).to be_success
        expect(@result.value!.length).to eq(1)
        expect(@result.value!.include?(person.hbx_id)).to be_truthy
      end

      it 'should update the income evidence due on for the applicant' do
        expect(applicant.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record)
        expect(applicant.income_evidence.due_on).to eq(TimeKeeper.date_of_record + 35.days)
      end

      it 'should add a verification history recording the update' do
        history = applicant.income_evidence.verification_histories.last
        expect(history.action).to eq("auto_extend_due_date")
        expect(history.updated_by).to eq("admin@ideacrew.com")
      end
    end

  end

  context 'failure' do
    context 'with invalid current due on' do
      it 'should fail' do
        result = subject.call({current_due_on: "08/08/2023"})
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid param for key current_due_on, must be a Date")
      end
    end

    context 'with invalid extend_by' do
      it 'should fail' do
        result = subject.call({extend_by: "08/08/2023"})
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid param for key extend_by, must be an Integer")
      end
    end

    context 'with invalid modified_by' do
      it 'should fail' do
        result = subject.call({modified_by: 345})
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid param for key modified_by, must be a String")
      end
    end
  end
end
