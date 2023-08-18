# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AutoExtendIncomeEvidence, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  describe 'extending income evidence verification due date on an individual applicant level' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095') }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
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

    let!(:income_evidence) do
      application.applicants.first.create_income_evidence(key: :income,
                                                          title: 'Income',
                                                          # Had to change from 'pending' to 'outstanding'?
                                                          aasm_state: 'outstanding',
                                                          due_on: TimeKeeper.date_of_record,
                                                          verification_outstanding: true,
                                                          is_satisfied: false)
    end

    before do
      # stub might look something like this?
      # allow(FinancialAssistanceRegistry).to receive(:[]).with(:auto_update_income_evidence_due_on).and_return(double(settings: double(days: double(item: 65))))

      family.create_eligibility_determination
      family.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                                outstanding_verification_earliest_due_date: TimeKeeper.date_of_record,
                                                outstanding_verification_document_status: 'Partially Uploaded')
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
    
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095') }
    let!(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person) }
    # let!(:family) { FactoryBot.create(:family, :with_family_of_four, person: person) }
    let(:applicant_1_due_date) { TimeKeeper.date_of_record + 10.days }
    let(:applicant_2_due_date) { TimeKeeper.date_of_record }
    let(:applicant_3_due_date) { TimeKeeper.date_of_record + 30.days }
    # let(:applicant_4_due_date) { TimeKeeper.date_of_record - 45.days } # income submitted/verified 48 days ago

    let!(:application) do
      FactoryBot.create(:application,
                        family_id: family.id,
                        aasm_state: "determined",
                        effective_date: (TimeKeeper.date_of_record -  2.days))
    end

    let!(:applicant_1) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 40.years,
                        is_primary_applicant: true,
                        family_member_id: family.family_members[0].id,
                        person_hbx_id: person.hbx_id,
                        addresses: [FactoryBot.build(:financial_assistance_address)])
    end

    let!(:applicant_2) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 42.years,
                        is_primary_applicant: true,
                        family_member_id: family.family_members[1].id,
                        person_hbx_id: family.family_members[1].hbx_id,
                        addresses: [FactoryBot.build(:financial_assistance_address)])
    end

    let!(:applicant_3) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 12.years,
                        is_primary_applicant: true,
                        family_member_id: family.family_members[2].id,
                        person_hbx_id: family.family_members[2].hbx_id,
                        addresses: [FactoryBot.build(:financial_assistance_address)])
    end

    # possible 4th applicant with verified income_evidence
    # let!(:applicant_4) do
    #   FactoryBot.create(:applicant,
    #                     application: application,
    #                     dob: TimeKeeper.date_of_record - 9.years,
    #                     is_primary_applicant: true,
    #                     family_member_id: family.family_members[3].id,
    #                     person_hbx_id: family.family_members[3].hbx_id,
    #                     addresses: [FactoryBot.build(:financial_assistance_address)])
    # end

    let!(:income_evidence_1) do
      applicant_1.create_income_evidence(key: :income,
                                              title: 'Income',
                                              aasm_state: 'outstanding',
                                              due_on: applicant_1_due_date,
                                              verification_outstanding: true,
                                              is_satisfied: false)
    end

    let!(:income_evidence_2) do
      applicant_2.create_income_evidence(key: :income,
                                                title: 'Income',
                                                aasm_state: 'outstanding',
                                                due_on: applicant_2_due_date,
                                                verification_outstanding: true,
                                                is_satisfied: false)
    end

    let!(:income_evidence_3) do
      applicant_3.create_income_evidence(key: :income,
                                              title: 'Income',
                                              aasm_state: 'outstanding',
                                              due_on: applicant_3_due_date,
                                              verification_outstanding: true,
                                              is_satisfied: false)
                                              # requirements to meet verification_outstanding: false vs is_satisfied: true
    end
    
    # let!(:income_evidence_4) do
    #   applicant_4.create_income_evidence(key: :income,
    #                                           title: 'Income',
    #                                           aasm_state: 'verified',
    #                                           due_on: applicant_4_due_date,
    #                                           verification_outstanding: false,
    #                                           is_satisfied: true)
    #                                           # requirements to meet verification_outstanding: false vs is_satisfied: true
    # end

    before do
      family.create_eligibility_determination
      family.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                                outstanding_verification_earliest_due_date: TimeKeeper.date_of_record,
                                                outstanding_verification_document_status: 'Partially Uploaded')

      # Is adding verification history necessary? I don't think the user necessarily had to have the date extended to test this case
      income_evidence_3.verification_histories.create(action: 'auto_extend_due_date', 
                                                        update_reason: 'Auto extended due date', 
                                                        updated_by: 'system')
      # # How is user_id determined with DateTime?
      # income_evidence_4.workflow_state_transitions.create(to_state: "verified", 
      #                                                     transition_at: (applicant_4_due_date - 2.days),
      #                                                     reason: "met minimum criteria", 
      #                                                     comment: "consumer provided proper documentation",
      #                                                     user_id: BSON::ObjectId.from_time(applicant_3_due_date - 2.days))

    end

    context 'success' do
      context 'with params given' do
        before do
          @result = subject.call({extend_by: 35, modified_by: 'admin@ideacrew.com'})

          applicant_1.reload
          applicant_2.reload
          applicant_3.reload
        end

        it 'should return success' do
          expect(@result).to be_success
          expect(@result.value!.length).to eq(2)

          expect(@result.value!.include?(family.family_members[0].hbx_id)).to be_truthy
          expect(@result.value!.include?(family.family_members[1].hbx_id)).to be_truthy
          expect(@result.value!.include?(family.family_members[2].hbx_id)).to be_falsy
        end

        it 'should update the income_evidence due_on date for the applicant where applicable' do
          expect(applicant_1.income_evidence.due_on).to eq(applicant_1_due_date + 35.days)
          expect(applicant_2.income_evidence.due_on).to eq(applicant_2_due_date + 35.days)
          expect(applicant_3.income_evidence.due_on).to eq(applicant_3_due_date) # Extension period not applicable to applicants ineligible for auto-renewal
        end

        it 'should update the family outstanding_verification_earliest_due_date to the earliest income_evidence due_on date' do
          ed = family.eligibility_determination

          # applicant_3 has the earliest income_evidence due_on date -- meaning the overall earliest due date for the family should also be this date
          expect(ed.outstanding_verification_earliest_due_date).to eq(applicant_3.income_evidence.due_on) 
        end
      end
    end
  end 
end