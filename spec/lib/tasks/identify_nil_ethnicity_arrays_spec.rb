# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/identify_nil_ethnicity_arrays"
Rake::Task.define_task(:environment)

RSpec.describe 'migrations:identify_nil_ethnicity_arrays', :type => :task, dbclean: :after_each do

  let!(:person1) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "12345", ethnicity: [nil])}
  let!(:person2) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "67890", ethnicity: ["Mexican"])}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person1)}
  let(:family_id) { family.id.to_s }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft", transfer_id: "tr123") }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.first.id, person_hbx_id: person1.hbx_id, is_primary_applicant: true, ethnicity: [nil]) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.last.id, person_hbx_id: person2.hbx_id, ethnicity: ["Mexican"]) }
  let(:rake) {Rake::Task["migrations:identify_nil_ethnicity_arrays"]}

  context "Rake task" do
    before do
      rake.reenable
      rake.invoke
    end

    after do
      Dir.glob("person_nil_ethnicity_*").each do |file_name|
        File.delete(file_name)
      end
      Dir.glob("applicant_nil_ethnicity_*").each do |file_name|
        File.delete(file_name)
      end
    end


    it 'should output csv report for identified persons' do
      report = Dir.glob("person_nil_ethnicity_*")
      expect(report).not_to be_empty
    end

    it 'should output csv report for identified applicants' do
      report = Dir.glob("applicant_nil_ethnicity_*")
      expect(report).not_to be_empty
    end
  end
end
