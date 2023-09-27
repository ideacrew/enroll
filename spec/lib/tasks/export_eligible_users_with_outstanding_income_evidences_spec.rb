# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/export_eligible_users_with_outstanding_income_evidences"
Rake::Task.define_task(:environment)

RSpec.describe 'reports:export_eligible_users_with_outstanding_income_evidences', :type => :task, dbclean: :after_each do
  let(:rake) { Rake::Task["reports:export_eligible_users_with_outstanding_income_evidences"] }
  let(:file_name) { "#{Rails.root}/users_with_outstanding_income_evidence_eligible_for_extension.csv" }

  describe "Rake Task" do
    let!(:person) { FactoryBot.create(:person) }
    let!(:person2) { FactoryBot.create(:person) }
    let!(:person3) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:family2) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person2) }
    let!(:family3) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person3) }

    let!(:application) { FactoryBot.create(:application, family_id: family.id, aasm_state: "determined", effective_date: (TimeKeeper.date_of_record - 12.days), assistance_year: '2023') }
    let!(:application2) { FactoryBot.create(:application, family_id: family2.id, aasm_state: "determined", effective_date: (TimeKeeper.date_of_record - 18.days), assistance_year: '2023') }
    let!(:application3) { FactoryBot.create(:application, family_id: family3.id, aasm_state: "determined", effective_date: (TimeKeeper.date_of_record - 18.days), assistance_year: '2023') }

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
                        application: application2,
                        dob: TimeKeeper.date_of_record - 25.years,
                        is_primary_applicant: false,
                        family_member_id: family2.family_members[0].id,
                        person_hbx_id: family2.family_members[0].person.hbx_id)
    end

    let!(:applicant4) do
      FactoryBot.create(:applicant,
                        application: application2,
                        dob: TimeKeeper.date_of_record - 27.years,
                        is_primary_applicant: false,
                        family_member_id: family2.family_members[1].id,
                        person_hbx_id: family2.family_members[1].person.hbx_id)
    end

    let!(:applicant5) do
      FactoryBot.create(:applicant,
                        application: application3,
                        dob: TimeKeeper.date_of_record - 40.years,
                        is_primary_applicant: true,
                        family_member_id: family3.family_members[0].id,
                        person_hbx_id: family3.family_members[0].person.hbx_id)
    end

    let(:applicant_1_original_due_date) { TimeKeeper.date_of_record - 65.days }
    let(:applicant_2_original_due_date) { TimeKeeper.date_of_record - 66.days }
    let(:applicant_3_original_due_date) { TimeKeeper.date_of_record - 97.days }
    let(:applicant_5_original_due_date) { TimeKeeper.date_of_record - 64.days }

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
      applicant5.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'rejected',
                                        due_on: applicant_5_original_due_date,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end


    before do
      min_date_1 = family.min_verification_due_date_on_family
      min_date_2 = family2.min_verification_due_date_on_family
      min_date_3 = family3.min_verification_due_date_on_family

      family.create_eligibility_determination
      family.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                               outstanding_verification_earliest_due_date: min_date_1,
                                               outstanding_verification_document_status: 'Partially Uploaded')

      family2.create_eligibility_determination
      family2.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                                outstanding_verification_earliest_due_date: min_date_2,
                                                outstanding_verification_document_status: 'Partially Uploaded')

      family3.create_eligibility_determination
      family3.eligibility_determination.update!(outstanding_verification_status: 'outstanding',
                                                outstanding_verification_earliest_due_date: min_date_3,
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

        expect(csv[0]["applicant_person_hbx_id"]).to eq(applicant.person_hbx_id)
        expect(csv[1]["applicant_person_hbx_id"]).to eq(applicant2.person_hbx_id)
        expect(csv[2]["applicant_person_hbx_id"]).to eq(applicant5.person_hbx_id)
      end

      it "should not update the income evidence due dates for any user" do
        expect(applicant.income_evidence.due_on).to eq(applicant_1_original_due_date)
        expect(applicant2.income_evidence.due_on).to eq(applicant_2_original_due_date)
        expect(applicant5.income_evidence.due_on).to eq(applicant_5_original_due_date)
      end
    end

    context "when generating a report and migrating data" do
      before do
        rake.reenable
        rake.invoke(true) # including 'true' as an arg when running the rake task will migrate the data
      end

      it "should update the income evidence due_on to the correct due date" do
        evidence = applicant.income_evidence
        projected_due_date = applicant_1_original_due_date + 65.days
        evidence.reload

        expect(evidence.due_on).to_not eq(applicant_1_original_due_date)
        expect(evidence.due_on).to eq(projected_due_date)
      end
    end

    context 'when there are invalid records' do
      before do
        allow_any_instance_of(Eligibilities::Evidence).to receive(:update).and_raise(StandardError)

        rake.reenable
        rake.invoke(true)
      end

      it 'should create the csv despite invalid records' do
        csv = CSV.read(file_name, headers: true)

        expect(csv.size).to eq(0)
      end
    end
  end
end