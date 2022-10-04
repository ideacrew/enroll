# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_expected_contribution_for_2022_active_determinations')

describe UpdateExpectedContributionFor2022ActiveDeterminations, dbclean: :after_each do
  let(:given_task_name) { 'update_expected_contribution_for_2022_active_determinations' }
  subject { UpdateExpectedContributionFor2022ActiveDeterminations.new(given_task_name, double(:current_scope => nil)) }

  after :all do
    input_file = "#{Rails.root}/applications_with_yearly_expected_contributions_for_aptc_households.csv"
    output_file = "#{Rails.root}/list_of_applications_with_updated_expected_contribution.csv"
    FileUtils.rm_rf(input_file) if File.exist?(input_file)
    FileUtils.rm_rf(output_file) if File.exist?(output_file)
  end

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe '#migrate' do
    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, hbx_assigned_id: '1000') }
    let(:tax_household) { FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.active_household) }
    let!(:tax_household_member) { FactoryBot.create(:tax_household_member, applicant_id: family.primary_family_member.id, tax_household: tax_household) }
    let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
    let(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
    let!(:applicant1) do
      FactoryBot.create(:financial_assistance_applicant,
                        eligibility_determination_id: ed.id,
                        application: application,
                        family_member_id: family.primary_family_member.id,
                        person_hbx_id: person.hbx_id)
    end

    context 'with valid data' do
      let!(:create_csv) do
        CSV.open("#{Rails.root}/applications_with_yearly_expected_contributions_for_aptc_households.csv", 'w', force_quotes: true) do |csv|
          csv << ['ApplicationHbxID','AptcHouseholdsWithYearlyExpectedContribution']
          csv << [application.hbx_id, { ed.hbx_assigned_id => 4100.0 }.to_json]
        end
      end

      before { subject.migrate }

      it 'should return non-zero values for eligibility_determination and tax_household' do
        ed.reload
        tax_household.reload
        expect(ed.yearly_expected_contribution).not_to be_zero
        expect(tax_household.yearly_expected_contribution).not_to be_zero
        expect(
          CSV.open("#{Rails.root}/list_of_applications_with_updated_expected_contribution.csv", 'r', headers: true).first.to_h
        ).to eq(
          { "PrimaryPersonHbxID" => person.hbx_id,
            "FamilyHbxAssignedId" => family.hbx_assigned_id.to_s,
            "ApplicationHbxID" => application.hbx_id }
        )
      end
    end

    context 'with invalid data' do
      before { subject.migrate }

      it 'should do nothing for eligibility_determination and tax_household' do
        expect(ed.yearly_expected_contribution).to be_zero
        expect(tax_household.yearly_expected_contribution).to be_zero
      end
    end
  end
end
