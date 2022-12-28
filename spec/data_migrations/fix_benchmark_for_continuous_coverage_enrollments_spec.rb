# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'fix_benchmark_for_continuous_coverage_enrollments')

describe FixBenchmarkForContinuousCoverageEnrollments, dbclean: :after_each do
  after :all do
    logger_name = "#{Rails.root}/log/fix_benchmark_for_continuous_coverage_enrollments_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    csv_name = "#{Rails.root}/benchmark_for_continuous_coverage_enrollments_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_1.csv"
    File.delete(logger_name) if File.exist?(logger_name)
    File.delete(csv_name) if File.exist?(csv_name)
  end

  subject { FixBenchmarkForContinuousCoverageEnrollments.new('fix_benchmark_for_continuous_coverage_enrollments', double(:current_scope => nil)) }

  describe '#migrate', :dbclean => :around_each do
    let!(:system_year) { Date.today.year }
    let!(:start_of_year) { Date.new(system_year) }
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, dob: Date.new(system_year - 25, 1, 19)) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_silver_health_product,
                        :individual_unassisted,
                        consumer_role_id: person.consumer_role.id,
                        effective_on: Date.new(system_year, 2, 1),
                        family: family,
                        household: family.active_household,
                        coverage_kind: 'health')
    end
    let!(:hbx_enrollment_member) do
      FactoryBot.create(:hbx_enrollment_member, is_subscriber: true, hbx_enrollment: hbx_enrollment, applicant_id: family.primary_applicant.id,
                                                coverage_start_on: start_of_year, eligibility_date: start_of_year)
    end
    let!(:tax_household_group) do
      thhg = family.tax_household_groups.create!(
        assistance_year: system_year,
        source: 'Admin',
        start_on: start_of_year,
        tax_households: [FactoryBot.build(:tax_household, household: family.active_household)]
      )
      thhg.tax_households.first.tax_household_members.create!(
        applicant_id: family.primary_applicant.id, is_ia_eligible: true
      )
      thhg
    end
    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: start_of_year)
      determination.grants.create(
        key: 'AdvancePremiumAdjustmentGrant',
        value: 10.00,
        start_on: start_of_year,
        end_on: start_of_year.end_of_year,
        assistance_year: system_year,
        member_ids: family.family_members.map(&:id).map(&:to_s),
        tax_household_id: tax_household_group.tax_households.first.id.to_s
      )

      determination
    end
    let!(:aptc_grant) { eligibility_determination.grants.first }
    let!(:tax_household_enrollment) do
      thh_enr = TaxHouseholdEnrollment.create(
        enrollment_id: hbx_enrollment.id,
        tax_household_id: aptc_grant.tax_household_id,
        household_benchmark_ehb_premium: 500.00,
        available_max_aptc: 375.00
      )
      thh_enr.tax_household_members_enrollment_members.create(
        family_member_id: hbx_enrollment.hbx_enrollment_members.first.applicant_id,
        hbx_enrollment_member_id: BSON::ObjectId.new,
        tax_household_member_id: BSON::ObjectId.new,
        age_on_effective_date: 20,
        relationship_with_primary: 'self',
        date_of_birth: start_of_year - 20.years
      )
    end

    let!(:slcsp_info) do
      OpenStruct.new(
        households: [OpenStruct.new(
          household_id: aptc_grant.tax_household_id,
          household_benchmark_ehb_premium: 200.00,
          members: family.family_members.collect do |fm|
            OpenStruct.new(
              family_member_id: fm.id.to_s,
              relationship_with_primary: fm.primary_relationship,
              date_of_birth: fm.dob,
              age_on_effective_date: fm.age_on(start_of_year)
            )
          end
        )]
      )
    end

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(start_of_year)
      EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
      allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
        double('IdentifySlcspWithPediatricDentalCosts',
               call: double(success: slcsp_info, success?: true))
      )
    end

    it 'updates household_benchmark_ehb_premium' do
      subject.migrate
      expect(
        TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id).first.household_benchmark_ehb_premium.to_f
      ).to eq(200.00)
    end
  end
end
