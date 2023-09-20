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
                      effective_date: (TimeKeeper.date_of_record - 12.days))
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

  describe 'extending income evidence verification due date on an individual applicant level' do
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

    before do
      allow(FinancialAssistanceRegistry[:auto_update_income_evidence_due_on].setting(:days)).to receive(:item).and_return(65)
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

      context 'previously auto extended then transition to attested or verified' do
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

        it 'should not update the applicant if the evidence is not in outstanding or rejected' do
          expect(applicant2.income_evidence.due_on).to eq(TimeKeeper.date_of_record)
          expect(applicant2.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record + 65.days)
        end

        it 'should not update the applicant if due on is not equal to the provided date' do
          expect(applicant3.income_evidence.due_on).to eq(TimeKeeper.date_of_record + 2.weeks)
          expect(applicant3.income_evidence.due_on).not_to eq(TimeKeeper.date_of_record + 65.days)
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

  describe 'extending income evidence verification due date on a family level' do
    # Test family with
    # 1 member eligible for income evidence extension (later due date)
    # 1 member eligible for income evidence extension (earlier due date)
    # 1 member ineligible for income evidence extension
    # Maybe add 1 member with complete verified income evidence?

    let!(:address) { FactoryBot.build(:financial_assistance_address) }
    let(:applicant_1_due_date) { TimeKeeper.date_of_record }
    let(:applicant_2_due_date) { TimeKeeper.date_of_record + 5.days }
    let(:applicant_3_due_date) { TimeKeeper.date_of_record + 30.days }

    let!(:income_evidence_1) do
      applicant.create_income_evidence(key: :income,
                                         title: 'Income',
                                         aasm_state: 'outstanding',
                                         due_on: applicant_1_due_date,
                                         verification_outstanding: true,
                                         is_satisfied: false)
    end

    let!(:income_evidence_2) do
      applicant2.create_income_evidence(key: :income,
                                         title: 'Income',
                                         aasm_state: 'outstanding',
                                         due_on: applicant_2_due_date,
                                         verification_outstanding: true,
                                         is_satisfied: false)
    end

    let!(:income_evidence_3) do
      applicant3.create_income_evidence(key: :income,
                                         title: 'Income',
                                         aasm_state: 'outstanding',
                                         due_on: applicant_3_due_date,
                                         verification_outstanding: true,
                                         is_satisfied: false)
    end

    before do
      # Enable to be able to use min_verification_due_date_on_family on family model
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_update_family_save).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:include_faa_outstanding_verifications).and_return(true)
      family.create_eligibility_determination
      family.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                               outstanding_verification_earliest_due_date: (TimeKeeper.date_of_record),
                                               outstanding_verification_document_status: 'Partially Uploaded')
    end

    context 'success' do
      context 'with params given' do
        before do
          @result = subject.call({extend_by: 35, modified_by: 'admin@ideacrew.com'})

          applicant.reload
          applicant2.reload
          applicant3.reload
          family.eligibility_determination.reload
        end

        it 'should return success' do
          expect(@result).to be_success
          expect(@result.value!.length).to eq(1)

          expect(@result.value!.include?(family.family_members[0].hbx_id)).to be_truthy
          expect(@result.value!.include?(family.family_members[1].hbx_id)).to be_falsy
          expect(@result.value!.include?(family.family_members[2].hbx_id)).to be_falsy
        end

        it 'should update the income_evidence due_on date for the applicant where applicable' do
          expect(applicant.income_evidence.due_on).to eq(applicant_1_due_date + 35.days)
          expect(applicant2.income_evidence.due_on).to eq(applicant_2_due_date) # extensions only happen if evidence due on is the current_due_on
          expect(applicant3.income_evidence.due_on).to eq(applicant_3_due_date) # Extension period not applicable to applicants ineligible for auto-renewal
        end

        it 'should update the family outstanding_verification_earliest_due_date to the earliest income_evidence due_on date' do
          # applicant2 has the earliest income_evidence due_on date -- meaning the overall earliest due date for the family should also be this date
          expect(family.eligibility_determination.outstanding_verification_earliest_due_date).to eq(applicant2.income_evidence.due_on)
        end
      end
    end
  end
end
