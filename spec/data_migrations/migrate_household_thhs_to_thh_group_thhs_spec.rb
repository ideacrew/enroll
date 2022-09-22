# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'migrate_household_thhs_to_thh_group_thhs')

describe MigrateHouseholdThhsToThhGroupThhs, dbclean: :after_each do
  after :all do
    logger_name = "#{Rails.root}/log/migrate_household_thhs_to_thh_group_thhs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    csv_name = "#{Rails.root}/thhs_to_premim_credits_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_1.csv"
    File.delete(logger_name) if File.exist?(logger_name)
    File.delete(csv_name) if File.exist?(csv_name)
  end

  subject { MigrateHouseholdThhsToThhGroupThhs.new('migrate_household_thhs_to_thh_group_thhs', double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql 'migrate_household_thhs_to_thh_group_thhs'
    end
  end

  describe 'changing tax household member csr percent' do
    let(:system_date) { TimeKeeper.date_of_record }
    let!(:person) { FactoryBot.create(:person) }
    let!(:person2) do
      per2 = FactoryBot.create(:person)
      person.ensure_relationship_with(per2, 'spouse')
      person.save!
      per2
    end
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:fm1) { family.primary_applicant }
    let!(:fm2) { FactoryBot.create(:family_member, family: family, person: person2) }
    let!(:th1) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: Date.new(system_date.year, 7, 31)) }
    let!(:thhm11) do
      FactoryBot.create(:tax_household_member,
                        applicant_id: fm1.id,
                        tax_household: th1,
                        is_ia_eligible: true,
                        csr_percent_as_integer: 73,
                        csr_eligibility_kind: 'csr_73')
    end
    let!(:thhm12) { FactoryBot.create(:tax_household_member, applicant_id: fm2.id, tax_household: th1, is_medicaid_chip_eligible: true) }
    let!(:ed1) { FactoryBot.create(:eligibility_determination, tax_household: th1) }

    let!(:th2) do
      FactoryBot.create(:tax_household,
                        household: family.active_household,
                        yearly_expected_contribution: 3100.50,
                        effective_ending_on: nil)
    end
    let!(:thhm21) { FactoryBot.create(:tax_household_member, applicant_id: fm1.id, tax_household: th2, is_totally_ineligible: true) }
    let!(:thhm22) { FactoryBot.create(:tax_household_member, applicant_id: fm2.id, tax_household: th2, is_medicaid_chip_eligible: true) }
    let!(:ed2) { FactoryBot.create(:eligibility_determination, tax_household: th2, max_aptc: 0.00) }

    context 'valid family' do
      before { subject.migrate }

      it 'should create TaxHouseholdGroups, TaxHouseholds and TaxHouseholdMembers' do
        thhgs = family.reload.tax_household_groups
        expect(thhgs.count).to eq(2)
        expect(thhgs.first.tax_households.count).to eq(1)
        expect(thhgs[1].tax_households.count).to eq(1)
        expect(thhgs.first.tax_households.first.yearly_expected_contribution).to eq(th2.yearly_expected_contribution)
        expect(thhgs[1].tax_households.first.yearly_expected_contribution).to eq(th1.yearly_expected_contribution)
        expect(thhgs.first.tax_households.first.tax_household_members.count).to eq(2)
        expect(thhgs[1].tax_households.first.tax_household_members.count).to eq(2)
      end
    end

    context 'invalid family' do
      before do
        th2.effective_ending_on = th2.effective_starting_on - 1.day
        th2.save(validate: false)
        subject.migrate
      end

      it 'should not create TaxHouseholdGroups as the family is invalid' do
        thhgs = family.reload.tax_household_groups
        expect(thhgs.count).to eq(0)
      end
    end
  end
end
