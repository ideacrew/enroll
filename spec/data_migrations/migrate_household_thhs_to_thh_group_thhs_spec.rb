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

  describe 'migrate household thhs to tax_household_group thhs' do
    let(:system_date) { TimeKeeper.date_of_record }
    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:person2) do
      per2 = FactoryBot.create(:person)
      person.ensure_relationship_with(per2, 'spouse')
      person.save!
      per2
    end
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:fm1) { family.primary_applicant }
    let!(:fm2) { FactoryBot.create(:family_member, family: family, person: person2) }

    let!(:th2) do
      FactoryBot.create(:tax_household,
                        household: family.active_household,
                        yearly_expected_contribution: nil,
                        effective_starting_on: Date.new(2022),
                        effective_ending_on: nil)
    end
    let!(:thhm21) { FactoryBot.create(:tax_household_member, applicant_id: fm1.id, tax_household: th2) }
    let!(:thhm22) { FactoryBot.create(:tax_household_member, applicant_id: fm2.id, tax_household: th2) }
    let!(:ed2) { FactoryBot.create(:eligibility_determination, tax_household: th2, max_aptc: 200.00) }

    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
    let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, aptc_csr_annual_household_income: '90000') }
    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        eligibility_determination_id: ed.id,
                        is_ia_eligible: true,
                        family_member_id: fm1.id,
                        is_claimed_as_tax_dependent: false,
                        is_required_to_file_taxes: true)
    end

    let!(:applicant2) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        eligibility_determination_id: ed.id,
                        is_ia_eligible: true,
                        family_member_id: fm2.id,
                        is_claimed_as_tax_dependent: true)
    end

    context 'with active and inactive thhs with all ia_eligible members' do
      let!(:th1) do
        FactoryBot.create(:tax_household,
                          household: family.active_household,
                          yearly_expected_contribution: nil,
                          effective_starting_on: Date.new(2022))
      end
      let!(:thhm11) do
        FactoryBot.create(:tax_household_member,
                          applicant_id: fm1.id,
                          tax_household: th1,
                          csr_percent_as_integer: 73,
                          csr_eligibility_kind: 'csr_73')
      end
      let!(:thhm12) { FactoryBot.create(:tax_household_member, applicant_id: fm2.id, tax_household: th1) }
      let!(:ed1) { FactoryBot.create(:eligibility_determination, tax_household: th1) }

      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          :individual_assisted,
                          :with_enrollment_members,
                          :with_health_product,
                          family: family,
                          applied_aptc_amount: 200,
                          enrollment_members: family.family_members,
                          effective_on: Date.new(2022))
      end

      let(:slcsp_info) do
        OpenStruct.new(
          households: [OpenStruct.new(
            household_id: th1.id,
            household_benchmark_ehb_premium: 200.00,
            members: family.family_members.collect do |fm|
              OpenStruct.new(
                family_member_id: fm.id.to_s,
                relationship_with_primary: fm.primary_relationship,
                date_of_birth: fm.dob,
                age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
              )
            end
          )]
        )
      end

      before :each do
        allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
          double('IdentifySlcspWithPediatricDentalCosts',
                 call: double(:value! => slcsp_info, :success? => true))
        )
        subject.migrate
      end

      it 'should create TaxHouseholdGroups, TaxHouseholds and TaxHouseholdMembers' do
        thhgs = family.reload.tax_household_groups
        expect(thhgs.count).to eq(2)
        expect(thhgs.first.tax_households.count).to eq(1)
        expect(thhgs[1].tax_households.count).to eq(1)
        expect(thhgs.first.tax_households.first.yearly_expected_contribution).not_to be_zero
        expect(thhgs[1].tax_households.first.yearly_expected_contribution).not_to be_zero
        expect(thhgs.first.tax_households.first.tax_household_members.count).to eq(2)
        expect(thhgs[1].tax_households.first.tax_household_members.count).to eq(2)
        expect(family.reload.eligibility_determination.grants.count).not_to be_zero
        expect(family.reload.eligibility_determination.subjects.first.csr_by_year(system_date.year)).not_to be_nil
        expect(::TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id).size).to eq 1
      end
    end

    context 'with only active thhs with all ia_eligible members' do
      before { subject.migrate }

      it 'should create TaxHouseholdGroups, TaxHouseholds and TaxHouseholdMembers' do
        thhgs = family.reload.tax_household_groups
        expect(thhgs.count).to eq(1)
        expect(thhgs.first.tax_households.count).to eq(1)
        expect(thhgs.first.tax_households.first.yearly_expected_contribution).not_to be_zero
        expect(thhgs.first.tax_households.first.tax_household_members.count).to eq(2)
        expect(family.reload.eligibility_determination.grants.count).not_to be_zero
        expect(family.reload.eligibility_determination.subjects.first.csr_by_year(system_date.year)).not_to be_nil
      end
    end

    context 'with active thhs and active 2022 tax household groups' do
      let!(:thhg) { FactoryBot.create(:tax_household_group, family: family, assistance_year: 2022) }

      it 'should not create any active TaxHouseholdGroups, TaxHouseholds and TaxHouseholdMembers' do
        expect(family.reload.tax_household_groups.active.count).to eq(1)
        expect(family.reload.tax_household_groups.count).to eq(1)
        subject.migrate
        expect(family.reload.tax_household_groups.active.count).to eq(1)
        expect(family.reload.tax_household_groups.count).to eq(1)
      end
    end

    context 'with only active thhs with all members ineligible for insurance assistance' do
      before do
        thhm21.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
        thhm22.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
        ed2.update_attributes(max_aptc: 0.0)
        subject.migrate
      end

      it 'should create TaxHouseholdGroups, TaxHouseholds and TaxHouseholdMembers' do
        thhgs = family.reload.tax_household_groups
        expect(thhgs.count).to eq(1)
        expect(thhgs.first.tax_households.count).to eq(1)
        expect(thhgs.first.tax_households.first.yearly_expected_contribution).not_to be_zero
        expect(thhgs.first.tax_households.first.tax_household_members.count).to eq(2)
        # Should not create any Aptc or Csr Grants as no APTC members.
        expect(family.reload.eligibility_determination.grants.count).to be_zero
        expect(family.reload.eligibility_determination.subjects.first.csr_by_year(system_date.year)).to be_nil
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

    context 'when sending invalid person hbx_ids' do

      it 'should not create TaxHouseholdGroups as the family is invalid' do
        ClimateControl.modify person_hbx_ids: '12345' do
          subject.migrate
          thhgs = family.reload.tax_household_groups
          expect(thhgs.count).to eq(0)
        end
      end
    end

    context 'when passing person hbx_ids' do

      it 'should create TaxHouseholdGroups as the family is valid' do
        ClimateControl.modify person_hbx_ids: " #{person.hbx_id}" do
          subject.migrate
          thhgs = family.reload.tax_household_groups
          expect(thhgs.count).to eq(1)
          expect(thhgs.first.tax_households.count).to eq(1)
          expect(thhgs.first.tax_households.first.yearly_expected_contribution).not_to be_zero
          expect(thhgs.first.tax_households.first.tax_household_members.count).to eq(2)
          expect(family.reload.eligibility_determination.grants.count).not_to be_zero
          expect(family.reload.eligibility_determination.subjects.first.csr_by_year(system_date.year)).not_to be_nil
        end
      end
    end
  end
end
