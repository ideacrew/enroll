# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'migrate_thhs_to_premium_credits')

describe MigrateThhsToPremiumCredits, dbclean: :after_each do
  let(:logger_name) { "#{Rails.root}/log/migrate_thhs_to_premium_credits_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log" }
  let(:csv_name) { "#{Rails.root}/thhs_to_premim_credits_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_1.csv" }

  after :all do
    logger_name = "#{Rails.root}/log/migrate_thhs_to_premium_credits_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    csv_name = "#{Rails.root}/thhs_to_premim_credits_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_1.csv"
    File.delete(logger_name) if File.exist?(logger_name)
    File.delete(csv_name) if File.exist?(csv_name)
  end

  subject { MigrateThhsToPremiumCredits.new('migrate_thhs_to_premium_credits', double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql 'migrate_thhs_to_premium_credits'
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

    let!(:th2) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: Date.new(system_date.year, 7, 31)) }
    let!(:thhm12) do
      FactoryBot.create(:tax_household_member, applicant_id: fm1.id, tax_household: th2, is_totally_ineligible: true, is_ia_eligible: false)
    end
    let!(:thhm22) do
      FactoryBot.create(:tax_household_member, applicant_id: fm2.id, tax_household: th2, is_medicaid_chip_eligible: true, is_ia_eligible: false)
    end
    let!(:ed2) { FactoryBot.create(:eligibility_determination, tax_household: th2, max_aptc: 0.00) }

    context 'valid family' do
      before { subject.migrate }

      it 'should create GroupPremiumCredit and MemberPremiumCredits' do
        gpcs = family.reload.group_premium_credits
        expect(gpcs.count).to eq(1)
        expect(gpcs.first.sub_group_id).to eq(th1.id)
        expect(gpcs.first.member_premium_credits.count).to eq(2)
        expect(
          gpcs.first.member_premium_credits.pluck(:kind, :value, :family_member_id)
        ).to eq([['aptc_eligible', 'true', fm1.id], ['csr', '73', fm1.id]])
        migrated_info = CSV.parse(File.read(csv_name), headers: true).first
        expect(migrated_info[2]).to eq(migrated_info[3])
        expect(migrated_info[0]).to eq(person.hbx_id)
        expect(migrated_info[1]).to eq(family.hbx_assigned_id.to_s)
      end
    end

    context 'invalid family' do
      before do
        th2.effective_ending_on = th2.effective_starting_on - 1.day
        th2.save(validate: false)
        subject.migrate
      end

      it 'should not create PremiumCredits as the family is invalid' do
        gpcs = family.reload.group_premium_credits
        expect(gpcs.count).to eq(0)
      end
    end
  end
end
