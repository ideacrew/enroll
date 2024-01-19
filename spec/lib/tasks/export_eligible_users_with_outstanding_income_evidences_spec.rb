# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/export_eligible_users_with_outstanding_income_evidences"
Rake::Task.define_task(:environment)

RSpec.describe 'reports:export_eligible_users_with_outstanding_income_evidences', :type => :task, dbclean: :after_each do
  let(:rake) { Rake::Task["reports:export_eligible_users_with_outstanding_income_evidences"] }
  let(:file_name) { "#{Rails.root}/users_with_outstanding_income_evidence_eligible_for_extension.csv" }

  let!(:person1) { FactoryBot.create(:person) }
  let!(:person2) { FactoryBot.create(:person) }
  let!(:person3) { FactoryBot.create(:person) }
  let!(:person4) { FactoryBot.create(:person) }

  let!(:family1) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person1) }
  let!(:family2) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person2) }
  let!(:family3) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person3) }
  let!(:family4) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person4) }

  let!(:application1) { FactoryBot.create(:application, family_id: family1.id, aasm_state: "determined") }
  let!(:application2) { FactoryBot.create(:application, family_id: family2.id, aasm_state: "determined") }
  let!(:application3) { FactoryBot.create(:application, family_id: family3.id, aasm_state: "determined") }
  let!(:application4) { FactoryBot.create(:application, family_id: family4.id, aasm_state: "determined") }

  # Both eligible for income_evidence extension
  let!(:applicant1) { FactoryBot.create(:applicant, application: application1, is_primary_applicant: true, family_member_id: family1.family_members[0].id, person_hbx_id: person1.hbx_id) }
  let!(:applicant2) { FactoryBot.create(:applicant, application: application1, family_member_id: family1.family_members[1].id, person_hbx_id: family1.family_members[1].person.hbx_id) }

  # One ineligible, one w/o income_evidence
  let!(:applicant3) { FactoryBot.create(:applicant, application: application2, is_primary_applicant: true, family_member_id: family2.family_members[0].id, person_hbx_id: person2.hbx_id) }
  let!(:applicant4) { FactoryBot.create(:applicant, application: application2, family_member_id: family2.family_members[1].id, person_hbx_id: family2.family_members[1].person.hbx_id) }

  # All members ineligible
  let!(:applicant5) { FactoryBot.create(:applicant, application: application3, is_primary_applicant: true, family_member_id: family3.family_members[0].id, person_hbx_id: person3.hbx_id) }

  # First member eligible, second ineligible for income_evidence extension
  let!(:applicant6) { FactoryBot.create(:applicant, application: application4, is_primary_applicant: true, family_member_id: family4.family_members[0].id, person_hbx_id: person4.hbx_id) }
  let!(:applicant7) { FactoryBot.create(:applicant, application: application4, family_member_id: family4.family_members[1].id, person_hbx_id: family4.family_members[1].person.hbx_id) }

  let(:applicant_1_original_due_date) { TimeKeeper.date_of_record - 65.days }
  let(:applicant_2_original_due_date) { TimeKeeper.date_of_record - 66.days }
  let(:applicant_3_original_due_date) { TimeKeeper.date_of_record - 34.days }
  let(:applicant_5_original_due_date) { TimeKeeper.date_of_record - 97.days }
  let(:applicant_6_original_due_date) { TimeKeeper.date_of_record - 40.days }
  let(:applicant_7_original_due_date) { TimeKeeper.date_of_record - 80.days }

  let!(:evidence1) { applicant1.create_income_evidence(key: :income, title: 'Income', aasm_state: 'outstanding', due_on: applicant_1_original_due_date, verification_outstanding: true, is_satisfied: false) }
  let!(:evidence2) { applicant2.create_income_evidence(key: :income, title: 'Income', aasm_state: 'rejected', due_on: applicant_2_original_due_date, verification_outstanding: true, is_satisfied: false) }
  let!(:evidence3) { applicant3.create_income_evidence(key: :income, title: 'Income', aasm_state: 'outstanding', due_on: applicant_3_original_due_date, verification_outstanding: true, is_satisfied: false) }
  let!(:evidence5) { applicant5.create_income_evidence(key: :income, title: 'Income', aasm_state: 'outstanding', due_on: applicant_5_original_due_date, verification_outstanding: true, is_satisfied: false) }
  let!(:evidence6) { applicant6.create_income_evidence(key: :income, title: 'Income', aasm_state: 'rejected', due_on: applicant_6_original_due_date, verification_outstanding: true, is_satisfied: false) }
  let!(:evidence7) { applicant7.create_income_evidence(key: :income, title: 'Income', aasm_state: 'outstanding', due_on: applicant_7_original_due_date, verification_outstanding: true, is_satisfied: false) }

  before do
    min_date1 = family1.min_verification_due_date_on_family
    min_date2 = family2.min_verification_due_date_on_family
    min_date3 = family3.min_verification_due_date_on_family
    min_date4 = family4.min_verification_due_date_on_family

    family1.create_eligibility_determination
    family1.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                              outstanding_verification_earliest_due_date: min_date1,
                                              outstanding_verification_document_status: 'Partially Uploaded')

    family2.create_eligibility_determination
    family2.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                              outstanding_verification_earliest_due_date: min_date2,
                                              outstanding_verification_document_status: 'Partially Uploaded')

    family3.create_eligibility_determination
    family3.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                              outstanding_verification_earliest_due_date: min_date3,
                                              outstanding_verification_document_status: 'Partially Uploaded')

    family4.create_eligibility_determination
    family4.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                              outstanding_verification_earliest_due_date: min_date4,
                                              outstanding_verification_document_status: 'Partially Uploaded')
  end

  after do
    File.delete(file_name)
  end

  describe "Generating a report of users eligible to have their income_evidence due_on date extended" do
    context "when generating a report on a dry run" do
      before do
        rake.reenable
        rake.invoke
      end

      it "should make a csv with correct number of eligible users" do
        csv = CSV.read(file_name, headers: true)

        expect(csv.size).to eq(3)

        expect(csv[0]["applicant_person_hbx_id"]).to eq(applicant1.person_hbx_id)
        expect(csv[1]["applicant_person_hbx_id"]).to eq(applicant2.person_hbx_id)
        expect(csv[2]["applicant_person_hbx_id"]).to eq(applicant3.person_hbx_id)
      end

      it "should not update the income evidence due dates for any user" do
        expect(evidence1.due_on).to eq(applicant_1_original_due_date)
        expect(evidence2.due_on).to eq(applicant_2_original_due_date)
        expect(evidence3.due_on).to eq(applicant_3_original_due_date)
      end
    end

    context "when generating a report and migrating data" do
      before do
        rake.reenable
        rake.invoke(true) # including 'true' as an arg when running the rake task will migrate the data

        evidence1.reload
        evidence2.reload
        evidence3.reload
        evidence5.reload
      end

      it "should update the income evidence due_on to the correct due date" do
        projected_due_date1 = applicant_1_original_due_date + 65.days
        projected_due_date3 = applicant_3_original_due_date + 65.days

        expect(evidence1.due_on).to_not eq(applicant_1_original_due_date)
        expect(evidence1.due_on).to eq(projected_due_date1)
        expect(evidence3.due_on).to_not eq(applicant_3_original_due_date)
        expect(evidence3.due_on).to eq(projected_due_date3)
      end

      it "should add a verification history to all relevant evidences" do
        evidence_histories = evidence1.verification_histories
        evidence_histories2 = evidence2.verification_histories

        expect(evidence_histories.size).to eq(1)
        expect(evidence_histories2.size).to eq(1)
      end

      it "should have a verification history with the correct action and updated_by fields" do
        evidence_histories = evidence1.verification_histories

        expect(evidence_histories.first.action).to eq('auto_extend_due_date')
        expect(evidence_histories.first.updated_by).to eq('system')
      end

      it "should not add a verification history to ineligilble evidences" do
        evidence_histories = evidence5.verification_histories

        expect(evidence_histories.size).to eq(0)
      end
    end

    context 'when there are invalid records' do
      before do
        evidence1.update(due_on: nil)

        rake.reenable
        rake.invoke(true)
      end

      it 'should create the csv despite and ignore invalid records' do
        csv = CSV.read(file_name, headers: true)

        expect(csv.size).to eq(2)
      end
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end