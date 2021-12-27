# frozen_string_literal: true

require 'rails_helper'

Rake.application.rake_require "tasks/fix_nil_ethnicity_arrays"
Rake::Task.define_task(:environment)

RSpec.describe 'migrations:fix_nil_ethnicity_arrays', :type => :task, dbclean: :after_each do

  let!(:person1) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "12345", ethnicity: [nil])}
  let!(:person2) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "67890", ethnicity: ["Mexican"])}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person1)}
  let(:family_id) { family.id.to_s }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft", transfer_id: "tr123") }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.first.id, person_hbx_id: person1.hbx_id, is_primary_applicant: true, ethnicity: [nil]) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.last.id, person_hbx_id: person2.hbx_id, ethnicity: ["Mexican"]) }
  let(:rake) {Rake::Task["migrations:fix_nil_ethnicity_arrays"]}

  context "Rake task" do
    before do
      rake.reenable
    end

    it 'should output person hbx id of primary applicant for all affected applications' do
      expected_output = "UPDATED APPLICATIONS (primary person_hbx_id):\n#{person1.hbx_id}\n"
      expect {rake.invoke}.to output(expected_output).to_stdout
    end

    it 'should remove nils from the person ethnicity array' do
      rake.invoke
      person1.reload
      expect(person1.ethnicity).to eq []
    end

    it 'should remove nils from the applicant ethnicity array' do
      rake.invoke
      applicant1.reload
      expect(applicant1.ethnicity).to eq []
    end

    it 'should not affect valid ethnicity arrays' do
      rake.invoke
      person2.reload
      applicant2.reload
      expect(person2.ethnicity).to eq ["Mexican"]
      expect(applicant2.ethnicity).to eq ["Mexican"]
    end
  end
end
