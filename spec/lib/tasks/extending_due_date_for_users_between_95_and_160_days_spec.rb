# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/export_users_with_due_dates_between_95_and_160_days"
Rake::Task.define_task(:environment)

RSpec.describe 'reports:export_users_with_due_dates_between_95_and_160_days', :type => :task, dbclean: :after_each do
  let(:rake) { Rake::Task["reports:export_users_with_due_dates_between_95_and_160_days"] }

  describe "Rake Task" do
    let!(:person)           { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role)     { person.consumer_role }
    let!(:family)           { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:hbx_enrollment)   { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: "coverage_selected", effective_on: TimeKeeper.date_of_record,
                                                 household: family.active_household, kind: "individual") }
    let!(:hbx_enrollment_member) { FactoryBot.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment,
                                                      eligibility_date: (TimeKeeper.date_of_record - 2.months), coverage_start_on: (TimeKeeper.date_of_record - 2.months),
                                                      is_subscriber: true, applicant_id: family.primary_applicant.id) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment,
                                                       eligibility_date: (TimeKeeper.date_of_record - 2.months), coverage_start_on: (TimeKeeper.date_of_record - 2.months),
                                                       is_subscriber: false, applicant_id: family.family_members[1].id) }

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

    let!(:address) { FactoryBot.build(:financial_assistance_address) }
    let(:applicant_1_due_date) { TimeKeeper.date_of_record - 159.days }
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
      rake.reenable
      rake.invoke
    end

    after do
      Dir.glob("fix_person_nil_ethnicity_*").each do |file_name|
        File.delete(file_name)
      end
      Dir.glob("fix_applicant_nil_ethnicity_*").each do |file_name|
        File.delete(file_name)
      end
    end


    context "collect all users with outstanding evidences between 95 and 160 days" do
      before :each do
        consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        subject.migrate
        hbx_enrollment.reload
        consumer_role.verification_types.map(&:reload)
      end

      it "should return is_any_member_outstanding? as true" do
        expect(hbx_enrollment.is_any_member_outstanding?).to be_truthy
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
      end

      it "should update the verification_types" do
        expect(consumer_role.verification_types[0].due_date).to be_truthy
      end
    end

    context "it should not update the due date if none of the enrolled members are outstanding" do

      before :each do
        consumer_role.update_attributes!(aasm_state: "verified")
        subject.migrate
        hbx_enrollment.reload
        consumer_role.reload
      end

      it "should change the aasm_state" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
      end

      it "should not update the verifcation_types" do
        expect(consumer_role.verification_types[0].due_date).to be_falsy
      end
    end

    context "it should consider only dep in verification outstanding" do
      before :each do
        dep_consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        subject.migrate
        hbx_enrollment.reload
        dep_consumer_role.verification_types.map(&:reload)
      end

      it "should update the aasm_state to verification type's due date" do
        dep_consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        dep_consumer_role.verification_types[2].update_attribute("validation_status","verification_outstanding")
        expect(hbx_enrollment.is_any_member_outstanding?).to be_truthy
      end

      it "should update the verifcation_types" do
        expect(dep_consumer_role.verification_types[0].due_date).to be_truthy
      end
    end
  end
end
