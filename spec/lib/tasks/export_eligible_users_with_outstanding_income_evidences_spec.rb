# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/export_eligible_users_with_outstanding_income_evidences"
Rake::Task.define_task(:environment)

RSpec.describe 'reports:export_eligible_users_with_outstanding_income_evidences', :type => :task, dbclean: :after_each do
  let(:rake) { Rake::Task["reports:export_eligible_users_with_outstanding_income_evidences"] }
  let(:file_name) { "#{Rails.root}/users_with_outstanding_income_evidence_due_dates_between_95_and_160_days.csv" }

  describe "Rake Task" do
    let!(:person) { FactoryBot.create(:person) }
    let!(:person2) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:family2) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person2) }

    let!(:application) { FactoryBot.create(:application, family_id: family.id, aasm_state: "determined", effective_date: (TimeKeeper.date_of_record - 12.days)) }
    let!(:application2) { FactoryBot.create(:application, family_id: family2.id, aasm_state: "determined", effective_date: (TimeKeeper.date_of_record - 18.days)) }

    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 40.years,
                        is_primary_applicant: true,
                        family_member_id: family.family_members[0].id,
                        person_hbx_id: person.hbx_id)
    end

    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 25.years,
                        is_primary_applicant: false,
                        family_member_id: family.family_members[1].id,
                        person_hbx_id: family.family_members[1].person.hbx_id)
    end

    let!(:applicant3) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: TimeKeeper.date_of_record - 25.years,
                        is_primary_applicant: false,
                        family_member_id: family.family_members[2].id,
                        person_hbx_id: family.family_members[2].person.hbx_id)
    end

    let!(:applicant4) do
      FactoryBot.create(:applicant,
                        application: application2,
                        dob: TimeKeeper.date_of_record - 40.years,
                        is_primary_applicant: true,
                        family_member_id: family2.family_members[0].id,
                        person_hbx_id: family2.family_members[0].person.hbx_id)
    end

    let(:applicant_1_original_due_date) { TimeKeeper.date_of_record - 159.days }
    let(:applicant_2_original_due_date) { TimeKeeper.date_of_record - 125.days }
    let(:applicant_3_original_due_date) { TimeKeeper.date_of_record - 50.days }
    let(:applicant_4_original_due_date) { TimeKeeper.date_of_record - 97.days }

    let!(:income_evidence_1) do
      applicant.create_income_evidence(key: :income,
                                       title: 'Income',
                                       aasm_state: 'outstanding',
                                       due_on: applicant_1_original_due_date,
                                       verification_outstanding: true,
                                       is_satisfied: false)
    end

    let!(:income_evidence_2) do
      applicant2.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'outstanding',
                                        due_on: applicant_2_original_due_date,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end

    let!(:income_evidence_3) do
      applicant3.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'outstanding',
                                        due_on: applicant_3_original_due_date,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end

    let!(:income_evidence_4) do
      applicant4.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'outstanding',
                                        due_on: applicant_4_original_due_date,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end

    before do
      family.create_eligibility_determination
      family.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                               outstanding_verification_earliest_due_date: TimeKeeper.date_of_record,
                                               outstanding_verification_document_status: 'Partially Uploaded')

      family2.create_eligibility_determination
      family2.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                                outstanding_verification_earliest_due_date: TimeKeeper.date_of_record,
                                                outstanding_verification_document_status: 'Partially Uploaded')
    end

    after do
      File.delete(file_name)
    end

    context "when generating a report on a dry run" do
      before do
        rake.reenable
        rake.invoke
      end

      it "should generate a csv with correct number of eligible users" do
        csv = CSV.read(file_name, headers: true)

        expect(csv.size).to eq(3)

        expect(csv[0]["user_hbx_id"]).to eq(applicant.person_hbx_id)
        expect(csv[1]["user_hbx_id"]).to eq(applicant2.person_hbx_id)
        expect(csv[2]["user_hbx_id"]).to eq(applicant4.person_hbx_id)
      end

      it "should not update the income evidence due dates for any user" do
        expect(applicant.income_evidence.due_on).to eq(applicant_1_original_due_date)
        expect(applicant2.income_evidence.due_on).to eq(applicant_2_original_due_date)
        expect(applicant4.income_evidence.due_on).to eq(applicant_4_original_due_date)
      end
    end

    context "when generating a report and migrating data" do
      before do
        rake.reenable
        rake.invoke(true) # including 'true' as an arg when running the rake task will migrate the data
      end

      it "should update the income evidence due_on to the correct due date" do
        evidence = applicant.income_evidence
        projected_due_date = applicant_1_original_due_date + 160.days
        evidence.reload

        expect(evidence.due_on).to_not eq(applicant_1_original_due_date)
        expect(evidence.due_on).to eq(projected_due_date)
      end
    end
  end
end
