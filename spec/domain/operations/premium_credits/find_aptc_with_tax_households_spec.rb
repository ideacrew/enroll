# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindAptcWithTaxHouseholds, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let(:result) { subject.call(params) }

  context 'invalid params' do
    context 'missing hbx_enrollment' do
      let(:params) do
        { hbx_enrollment: nil }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Invalid params. hbx_enrollment should be an instance of Hbx Enrollment')
      end
    end

    context 'missing effective_on' do
      let(:params) do
        { hbx_enrollment: HbxEnrollment.new }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing effective_on')
      end
    end

    context 'missing tax households' do
      let(:hbx_enrollment) { HbxEnrollment.new }
      let(:params) do
        { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing effective_on')
      end
    end
  end

  context 'valid params' do
    before do
      allow(hbx_enrollment).to receive(:total_ehb_premium).and_return 2000.00
    end

    let(:params) do
      { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on, tax_households: tax_households }
    end

    context 'not eligible for aptc' do
      context 'with no eligibility_determination' do
        let(:person) { FactoryBot.create(:person) }
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :individual_shopping,
                            :with_silver_health_product,
                            :with_enrollment_members,
                            enrollment_members: family.family_members,
                            family: family)
        end

        let(:tax_households) { [] }

        it 'returns zero available aptc' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 0.0
        end
      end
    end

    context 'eligible for aptc' do
      let(:family) do
        family = FactoryBot.build(:family, person: primary)
        family.family_members = [
          FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
          FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent)
        ]

        family.person.person_relationships.push PersonRelationship.new(relative_id: dependent.id, kind: 'spouse')
        family.save
        family
      end

      let(:dependent) { FactoryBot.create(:person) }
      let(:primary) { FactoryBot.create(:person) }
      let(:primary_applicant) { family.primary_applicant }
      let(:dependents) { family.dependents }

      context 'with single tax household group' do
        before do
          allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
            double('IdentifySlcspWithPediatricDentalCosts',
                   call: double(:value! => slcsp_info, :success? => true))
          )
        end

        let!(:tax_household_group) do
          tax_household_group = family.tax_household_groups.create!(
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year
          )

          th = FactoryBot.build(:tax_household, household: family.active_household, yearly_expected_contribution: yearly_expected_contribution)
          th.tax_household_members = [
            FactoryBot.build(:tax_household_member, applicant_id: primary_applicant.id, tax_household: th),
            FactoryBot.build(:tax_household_member, applicant_id: dependents.first.id, tax_household: th)
          ]

          tax_household_group.tax_households << th
          tax_household_group.save
          tax_household_group
        end

        let!(:inactive_tax_household_group) do
          tax_household_group = family.tax_household_groups.create!(
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year
          )

          th = FactoryBot.build(:tax_household, household: family.active_household, yearly_expected_contribution: yearly_expected_contribution)
          th.tax_household_members = [
            FactoryBot.build(:tax_household_member, applicant_id: primary_applicant.id, tax_household: th),
            FactoryBot.build(:tax_household_member, applicant_id: dependents.first.id, tax_household: th)
          ]

          tax_household_group.tax_households << th
          tax_household_group.save
          tax_household_group
        end

        let(:tax_households) do
          tax_household_group.tax_households
        end

        let(:tax_household) do
          tax_households.first
        end

        let(:eligibility_determination) do
          determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
          determination.grants.create(
            key: "AdvancePremiumAdjustmentGrant",
            value: yearly_expected_contribution,
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year,
            assistance_year: TimeKeeper.date_of_record.year,
            member_ids: family.family_members.map(&:id).map(&:to_s),
            tax_household_id: tax_household.id
          )

          determination
        end

        let(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :individual_shopping,
                            :with_silver_health_product,
                            :with_enrollment_members,
                            enrollment_members: [primary_applicant],
                            family: family)
        end

        let(:yearly_expected_contribution) { 125.00 * 12 }

        let(:slcsp_info) do
          OpenStruct.new(
            households: [OpenStruct.new(
              household_id: tax_household.id,
              household_benchmark_ehb_premium: benchmark_premium,
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

        let(:primary_bp) { 500.00 }
        let(:dependent_bp) { 600.00 }

        context 'when benchmark_premium & household_info is nil' do
          let(:benchmark_premium) { nil }

          it 'creates tax household enrollment' do
            expect(result.success?).to eq true
            expect(result.value!).to eq 0
            expect(TaxHouseholdEnrollment.all.size).to eq 1
            expect(TaxHouseholdEnrollment.all.first.tax_household_members_enrollment_members.size).to eq 1
          end
        end

        context 'without any coinciding enrollments' do
          let(:benchmark_premium) { primary_bp }

          it 'returns difference of benchmark premiums and monthly_expected_contribution as total available aptc' do
            expect(result.success?).to eq true
            expect(result.value!).to eq 375.00
          end
        end

        context 'with member coverage_start_on different from effective_on' do
          let(:benchmark_premium) { primary_bp }
          let(:today) { TimeKeeper.date_of_record }
          let(:dob_year) { today.year - 15 }

          before do
            hbx_enrollment.update_attributes!(effective_on: TimeKeeper.date_of_record)
            hbx_enrollment.hbx_enrollment_members.each do |mmbr|
              mmbr.person.update_attributes!(dob: Date.new(dob_year, today.month, today.beginning_of_month.day) - 15.days)
              mmbr.update_attributes!(coverage_start_on: 1.month.ago.to_date)
            end
          end

          it 'returns success' do
            expect(result.success?).to eq true
          end
        end

        context 'with coinciding enrollments' do
          let!(:prev_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              elected_aptc_pct: 1.0,
                              enrollment_members: [primary_applicant],
                              family: family,
                              applied_aptc_amount: 375.00,
                              aasm_state: 'coverage_selected')
          end

          let!(:tax_household_enrollment) do
            TaxHouseholdEnrollment.create(
              enrollment_id: prev_enrollment.id,
              tax_household_id: tax_household.id,
              household_benchmark_ehb_premium: 500.00,
              available_max_aptc: 375.00
            )
          end

          let!(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              enrollment_members: dependents,
                              family: family)
          end

          let(:benchmark_premium) { dependent_bp }

          context 'when not excluding any enrollments' do
            let(:params) do
              { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on, tax_households: tax_household_group.tax_households }
            end

            it 'creates tax household enrollment' do
              expect(result.success?).to eq true
              expect(TaxHouseholdEnrollment.all.size).to eq 2
            end

            it 'returns benchmark premiums when monthly_expected_contribution is met' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 600.00
            end
          end

          context 'when excluding any enrollments' do
            let(:params) do
              { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on, exclude_enrollments_list: [prev_enrollment.hbx_id], tax_households: tax_household_group.tax_households }
            end

            it 'creates tax household enrollment' do
              expect(result.success?).to eq true
              expect(TaxHouseholdEnrollment.all.size).to eq 2
            end

            it 'returns benchmark premiums when monthly_expected_contribution is met' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 475.00
            end
          end
        end
      end
    end
  end
end
