# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindAptc, dbclean: :after_each do
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
  end

  context 'valid params' do
    before do
      allow(hbx_enrollment).to receive(:total_ehb_premium).and_return 2000.00
    end

    let(:params) do
      { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on }
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

        it 'returns zero available aptc' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 0.0
        end

        it 'should not create tax_household enrollments' do
          result
          expect(TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id).size).to eq 0
        end
      end

      context 'with eligibility_determination and without any aptc grants for family' do

        let(:person) { FactoryBot.create(:person) }
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let!(:eligibility_determination) { family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year) }
        let(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :individual_shopping,
                            :with_silver_health_product,
                            :with_enrollment_members,
                            enrollment_members: family.family_members,
                            effective_on: TimeKeeper.date_of_record.beginning_of_month,
                            family: family)
        end

        let!(:tax_household_group) do
          family.tax_household_groups.create!(
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            tax_households: [
              FactoryBot.build(:tax_household, household: family.active_household)
            ]
          )
        end

        it 'returns zero available aptc' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 0.0
        end

        context 'no tax household member records exists' do
          it 'should not create tax household enrollments' do
            result
            expect(TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id).size).to eq 0
          end
        end

        context 'when thh records exists for enrolled members' do
          let!(:tax_household_group) do
            family.tax_household_groups.create!(
              assistance_year: TimeKeeper.date_of_record.year,
              source: 'Admin',
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              tax_households: [
                FactoryBot.build(:tax_household, household: family.active_household)
              ]
            )
          end
          let(:tax_household) { tax_household_group.tax_households.first }
          let!(:tax_household_member) { tax_household.tax_household_members.create(applicant_id: family.family_members[0].id) }

          it 'should create tax household enrollments' do
            result
            expect(TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id).size).not_to eq 0
          end
        end
      end

      context 'when enrolled members does not have a aptc grants' do
        let(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person) }
        let(:person) { FactoryBot.create(:person) }
        let(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :individual_shopping,
                            :with_silver_health_product,
                            :with_enrollment_members,
                            enrollment_members: [family.primary_applicant],
                            family: family)
        end
        let(:non_primary_fm) { family.family_members.detect { |family_member| !family_member.is_primary_applicant? && family_member.is_active? } }
        let!(:eligibility_determination) do
          determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
          determination.grants.create(
            key: "AdvancePremiumAdjustmentGrant",
            value: 1200.0,
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year,
            assistance_year: TimeKeeper.date_of_record.year,
            member_ids: [non_primary_fm.id]
          )

          determination
        end

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
          family.tax_household_groups.create!(
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            tax_households: [
              FactoryBot.build(:tax_household, household: family.active_household)
            ]
          )
        end

        let!(:inactive_tax_household_group) do
          family.tax_household_groups.create!(
            created_at: TimeKeeper.date_of_record - 1.months,
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year,
            tax_households: [
              FactoryBot.build(:tax_household, household: family.active_household)
            ]
          )
        end

        let(:tax_household) do
          tax_household_group.tax_households.first
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

        let(:aptc_grant) { eligibility_determination.grants.first }

        let(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :individual_shopping,
                            :with_silver_health_product,
                            :with_enrollment_members,
                            enrollment_members: [primary_applicant],
                            effective_on: TimeKeeper.date_of_record.beginning_of_month,
                            family: family)
        end

        let(:yearly_expected_contribution) { 125.00 * 12 }

        let(:slcsp_info) do
          OpenStruct.new(
            households: [OpenStruct.new(
              household_id: aptc_grant.tax_household_id,
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

          it 'returns zero $' do
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

        context 'with inactive tax household group' do
          before do
            family.tax_household_groups.active.first.update_attributes!(end_on: TimeKeeper.date_of_record.end_of_year)
          end
          let(:benchmark_premium) { primary_bp }

          it 'returns difference of benchmark premiums and monthly_expected_contribution as total available aptc' do
            expect(result.success?).to eq true
            expect(result.value!).to eq 375.00
          end
        end

        context 'for tax_household_member_enrollment_member' do
          let(:benchmark_premium) { primary_bp }

          before do
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
              date_of_birth: TimeKeeper.date_of_record - 20.years
            )
          end

          it 'updates tax_household_member_enrollment_member with correct hbx_enrollment_member_id' do
            result
            expect(
              TaxHouseholdEnrollment.first.tax_household_members_enrollment_members.first.hbx_enrollment_member_id
            ).to eq(
              hbx_enrollment.hbx_enrollment_members.first.id
            )
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
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              applied_aptc_amount: 375.00,
                              aasm_state: 'coverage_selected')
          end

          let!(:tax_household_enrollment) do
            TaxHouseholdEnrollment.create(
              enrollment_id: prev_enrollment.id,
              tax_household_id: aptc_grant.tax_household_id,
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
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              family: family)
          end

          let(:benchmark_premium) { dependent_bp }

          context 'when not excluding any enrollments' do
            let(:params) do
              { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on }
            end

            it 'returns benchmark premiums when monthly_expected_contribution is met' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 600.00
            end
          end

          context 'when excluding any enrollments' do
            let(:params) do
              { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on, exclude_enrollments_list: [prev_enrollment.hbx_id] }
            end

            it 'returns benchmark premiums when monthly_expected_contribution is met' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 475.00
            end
          end
        end

        context 'when a member is not eligible for aptc in a family and enrolling seperately' do
          let!(:eligibility_determination) do
            determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
            determination.grants.create(
              key: "AdvancePremiumAdjustmentGrant",
              value: yearly_expected_contribution,
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              end_on: TimeKeeper.date_of_record.end_of_year,
              assistance_year: TimeKeeper.date_of_record.year,
              member_ids: [family.primary_applicant.id.to_s],
              tax_household_id: tax_household.id
            )

            determination
          end

          let!(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              enrollment_members: dependents,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              family: family)
          end

          let(:benchmark_premium) { dependent_bp }

          it 'returns 0$ for aptc' do
            expect(result.success?).to eq true
            expect(result.value!).to eq 0.00
          end
        end

        context 'with coinciding enrollments after application redetermination & dependent is non applicant' do
          let!(:prev_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              elected_aptc_pct: 1.0,
                              enrollment_members: family.family_members,
                              family: family,
                              applied_aptc_amount: 975.00,
                              aasm_state: 'coverage_terminated',
                              effective_on: TimeKeeper.date_of_record.beginning_of_month)
          end

          let!(:eligibility_determination) do
            determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
            determination.grants.create(
              key: "AdvancePremiumAdjustmentGrant",
              value: yearly_expected_contribution,
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              end_on: TimeKeeper.date_of_record.end_of_year,
              assistance_year: TimeKeeper.date_of_record.year,
              member_ids: [family.primary_applicant.id.to_s],
              tax_household_id: tax_household.id
            )

            determination
          end

          let(:params) do
            { hbx_enrollment: hbx_enrollment, effective_on: hbx_enrollment.effective_on }
          end

          context 'when both members enrolling' do
            let(:benchmark_premium) { primary_bp }

            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: family.family_members,
                                family: family,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month)
            end

            it 'returns difference of benchmark premiums and monthly_expected_contribution as total available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 375.00
            end
          end

          context 'when only primary is enrolling' do
            let(:benchmark_premium) { primary_bp }
            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [family.primary_applicant],
                                family: family,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month)
            end

            it 'returns difference of benchmark premiums and monthly_expected_contribution as total available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 375.00
            end
          end

          context 'when only dependent is enrolling' do
            let(:benchmark_premium) { dependent_bp }
            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: dependents,
                                family: family,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month)
            end

            it 'returns 0$ as aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 0.00
            end
          end
        end

        context 'benchmark_premium is less than monthly_expected_contribution' do
          let(:yearly_expected_contribution) { 375.00 * 12 }

          let(:slcsp_info) do
            OpenStruct.new(
              households: [OpenStruct.new(
                household_id: aptc_grant.tax_household_id,
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

          let(:primary_bp) { 1100.00 }
          let(:dependent_bp) { 320.00 }

          context 'when dependent is enrolling' do
            let(:benchmark_premium) { dependent_bp }
            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: dependents,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns 0$ as available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 0.00
            end
          end

          context 'when primary is enrolling with a coinciding dependent enrollment' do
            let(:benchmark_premium) { primary_bp }

            let!(:prev_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                elected_aptc_pct: 1.0,
                                enrollment_members: dependents,
                                family: family,
                                applied_aptc_amount: 0.00,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                aasm_state: 'coverage_selected')
            end

            let!(:tax_household_enrollment) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment.id,
                tax_household_id: aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: 320.00,
                available_max_aptc: 0.0
              )
            end

            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                enrollment_members: [primary_applicant],
                                family: family)
            end

            it 'returns difference of benchmark_premium and remaining monthly_expected_contribution that was met from prev enrollment' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 1045.00
            end
          end
        end

        context 'three members enrolling in different plans' do
          let(:family) do
            family = FactoryBot.build(:family, person: primary)
            family.family_members = [
              FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent1),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent2)
            ]

            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent1.id, kind: 'spouse')
            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
            family.save
            family
          end

          let(:dependent1) { FactoryBot.create(:person) }
          let(:dependent2) { FactoryBot.create(:person) }

          let(:yearly_expected_contribution) { 550.00 * 12 }

          let(:slcsp_info) do
            OpenStruct.new(
              households: [OpenStruct.new(
                household_id: aptc_grant.tax_household_id,
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

          let(:primary_bp) { 1100.00 }
          let(:dependent1_bp) { 1130.00 }
          let(:dependent2_bp) { 320.00 }

          context 'when primary is enrolling with no active enrollments' do
            let(:benchmark_premium) { primary_bp }
            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [primary_applicant],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns difference of benchmark premiums and monthly_expected_contribution as total available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq(1100.00 - (yearly_expected_contribution / 12))
            end
          end

          context 'when dependent1 is enrolling with existing enrollment from primary' do
            let(:benchmark_premium) { dependent1_bp }

            let!(:prev_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                elected_aptc_pct: 1.0,
                                enrollment_members: [primary_applicant],
                                family: family,
                                applied_aptc_amount: 550.00,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                aasm_state: 'coverage_selected')
            end

            let!(:tax_household_enrollment) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment.id,
                tax_household_id: aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: 1100.00,
                available_max_aptc: 550.0
              )
            end

            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [dependents[0]],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns difference of benchmark_premium and remaining monthly_expected_contribution that was met from prev enrollment' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 1130.00
            end
          end

          context 'when dependent2 is enrolling with existing enrollment from primary' do
            let(:benchmark_premium) { dependent2_bp }
            let!(:prev_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                elected_aptc_pct: 1.0,
                                enrollment_members: [primary_applicant],
                                family: family,
                                applied_aptc_amount: 550.00,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                aasm_state: 'coverage_selected')
            end

            let!(:prev_enrollment2) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [dependents[0]],
                                family: family,
                                applied_aptc_amount: 1130.00,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                aasm_state: 'coverage_selected')
            end

            let!(:tax_household_enrollment1) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment.id,
                tax_household_id: aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: 550.00,
                available_max_aptc: 550.0
              )
            end

            let!(:tax_household_enrollment2) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment2.id,
                tax_household_id: aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: 1130.00,
                available_max_aptc: 1130.0
              )
            end

            let!(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [dependents[1]],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns difference of benchmark_premium and remaining monthly_expected_contribution that was met from prev enrollment' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 0
            end
          end
        end
      end

      context 'with multiple tax household groups' do
        let!(:eligibility_determination) do
          determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
          determination
        end

        let(:primary_grant) do
          eligibility_determination.grants.create(
            key: "AdvancePremiumAdjustmentGrant",
            value: yearly_expected_contribution1,
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year,
            assistance_year: TimeKeeper.date_of_record.year,
            member_ids: [primary_applicant.id.to_s],
            tax_household_id: primary_tax_household.id
          )
        end

        let(:dependents_grant) do
          eligibility_determination.grants.create(
            key: "AdvancePremiumAdjustmentGrant",
            value: yearly_expected_contribution2,
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            end_on: TimeKeeper.date_of_record.end_of_year,
            assistance_year: TimeKeeper.date_of_record.year,
            member_ids: dependents.map(&:id).map(&:to_s),
            tax_household_id: dependents_tax_household.id
          )
        end

        let(:tax_household_group) do
          family.tax_household_groups.create!(
            assistance_year: TimeKeeper.date_of_record.year,
            source: 'Admin',
            start_on: TimeKeeper.date_of_record.beginning_of_year,
            tax_households: [
              FactoryBot.build(:tax_household, household: family.active_household),
              FactoryBot.build(:tax_household, household: family.active_household)
            ]
          )
        end

        let(:primary_tax_household) do
          tax_household_group.tax_households.first
        end

        let(:dependents_tax_household) do
          tax_household_group.tax_households.second
        end

        let(:primary_aptc_grant) { eligibility_determination.reload.grants.first }
        let(:dependents_aptc_grant) { eligibility_determination.reload.grants.second }

        before do
          primary_grant
          dependents_grant
          allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
            double('IdentifySlcspWithPediatricDentalCosts',
                   call: double(:value! => slcsp_info, :success? => true))
          )
        end

        context 'without coinciding enrollments' do

          let(:slcsp_info) do
            OpenStruct.new(
              households: [
                OpenStruct.new(
                  household_id: primary_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: primary_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                ),
                OpenStruct.new(
                  household_id: dependents_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: dependents_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                )
              ]
            )
          end

          let(:primary_benchmark_premium) { 1100.00 }
          let(:dependents_benchmark_premium) { 320.00 }

          let(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              enrollment_members: family.family_members,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              family: family)
          end

          let(:yearly_expected_contribution1) { 375.00 * 12 }
          let(:yearly_expected_contribution2) { 100.00 * 12}

          it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
            expect(result.success?).to eq true
            expect(result.value!).to eq(725.00 + 220.00)
          end
        end

        context 'with coinciding enrollments' do
          let(:family) do
            family = FactoryBot.build(:family, person: primary)
            family.family_members = [
              FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent1),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent2)
            ]

            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent1.id, kind: 'spouse')
            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
            family.save
            family
          end

          let(:dependent1) { FactoryBot.create(:person) }
          let(:dependent2) { FactoryBot.create(:person) }

          let(:yearly_expected_contribution) { 550.00 * 12 }

          let(:slcsp_info) do
            OpenStruct.new(
              households: [
                OpenStruct.new(
                  household_id: dependents_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: dependents_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                )
              ]
            )
          end

          let(:primary_benchmark_premium) { 450.00 }
          let(:dependents_benchmark_premium) { 583.00 }

          let(:yearly_expected_contribution1) { 343.75 * 12 }
          let(:yearly_expected_contribution2) { 100.00 * 12 }

          let!(:prev_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              elected_aptc_pct: 1.0,
                              enrollment_members: [primary_applicant],
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              family: family,
                              aasm_state: 'coverage_selected')
          end

          let(:hbx_enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              :individual_shopping,
                              :with_silver_health_product,
                              :with_enrollment_members,
                              effective_on: TimeKeeper.date_of_record.beginning_of_month,
                              enrollment_members: dependents,
                              family: family)
          end

          let!(:tax_household_enrollment) do
            TaxHouseholdEnrollment.create(
              enrollment_id: prev_enrollment.id,
              tax_household_id: primary_grant.tax_household_id,
              household_benchmark_ehb_premium: 320.00,
              available_max_aptc: 106.25
            )
          end

          it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
            expect(result.success?).to eq true
            expect(result.value!).to eq 483.00
          end
        end

        context 'shopping with mixed tax households' do
          let(:family) do
            family = FactoryBot.build(:family, person: primary)
            family.family_members = [
              FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent1),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent2)
            ]

            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent1.id, kind: 'spouse')
            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
            family.save
            family
          end

          let(:dependent1) { FactoryBot.create(:person) }
          let(:dependent2) { FactoryBot.create(:person) }

          let(:yearly_expected_contribution) { 550.00 * 12 }

          let(:primary_benchmark_premium) { 450.00 }
          let(:dependent1_benchmark_premium) { 310.00 }
          let(:dependent2_benchmark_premium) { 260.00 }

          let(:yearly_expected_contribution1) { 343.75 * 12 }
          let(:yearly_expected_contribution2) { 100.00 * 12 }

          context 'when primary & dependent2 enrolling' do
            let(:slcsp_info) do
              OpenStruct.new(
                households: [
                  OpenStruct.new(
                    household_id: primary_aptc_grant.tax_household_id,
                    household_benchmark_ehb_premium: primary_benchmark_premium,
                    members: family.family_members.collect do |fm|
                      OpenStruct.new(
                        family_member_id: fm.id.to_s,
                        relationship_with_primary: fm.primary_relationship,
                        date_of_birth: fm.dob,
                        age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                      )
                    end
                  ),
                  OpenStruct.new(
                    household_id: dependents_aptc_grant.tax_household_id,
                    household_benchmark_ehb_premium: dependent2_benchmark_premium,
                    members: family.family_members.collect do |fm|
                      OpenStruct.new(
                        family_member_id: fm.id.to_s,
                        relationship_with_primary: fm.primary_relationship,
                        date_of_birth: fm.dob,
                        age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                      )
                    end
                  )
                ]
              )
            end
            let(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [primary_applicant, dependents[1]],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
              expect(result.success?).to eq true
              expect(result.value!).to eq((106.25 + 160.00).round)
            end
          end

          context 'when dependent1 is enrolling with coinciding enrollment' do
            let(:slcsp_info) do
              OpenStruct.new(
                households: [
                  OpenStruct.new(
                    household_id: dependents_aptc_grant.tax_household_id,
                    household_benchmark_ehb_premium: dependent1_benchmark_premium,
                    members: family.family_members.collect do |fm|
                      OpenStruct.new(
                        family_member_id: fm.id.to_s,
                        relationship_with_primary: fm.primary_relationship,
                        date_of_birth: fm.dob,
                        age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                      )
                    end
                  )
                ]
              )
            end

            let!(:prev_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                elected_aptc_pct: 1.0,
                                enrollment_members: [primary_applicant, dependents[1]],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family,
                                aasm_state: 'coverage_selected')
            end

            let!(:tax_household_enrollment1) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment.id,
                tax_household_id: primary_aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: primary_benchmark_premium,
                available_max_aptc: 106.25
              )
            end

            let!(:tax_household_enrollment2) do
              TaxHouseholdEnrollment.create(
                enrollment_id: prev_enrollment.id,
                tax_household_id: dependents_aptc_grant.tax_household_id,
                household_benchmark_ehb_premium: dependent2_benchmark_premium,
                available_max_aptc: 160
              )
            end

            let(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: [dependents[0]],
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
              expect(result.success?).to eq true
              expect(result.value!).to eq 310.00
            end
          end
        end

        context 'shopping with mixed tax households with primary not re-enrolling' do
          let(:primary_grant) do
            eligibility_determination.grants.create(
              key: "AdvancePremiumAdjustmentGrant",
              value: yearly_expected_contribution1,
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              end_on: TimeKeeper.date_of_record.end_of_year,
              assistance_year: TimeKeeper.date_of_record.year,
              member_ids: [primary_applicant.id.to_s, dependents.first.id.to_s],
              tax_household_id: primary_tax_household.id
            )
          end

          let(:dependents_grant) do
            eligibility_determination.grants.create(
              key: "AdvancePremiumAdjustmentGrant",
              value: yearly_expected_contribution2,
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              end_on: TimeKeeper.date_of_record.end_of_year,
              assistance_year: TimeKeeper.date_of_record.year,
              member_ids: [dependents.second.id.to_s],
              tax_household_id: dependents_tax_household.id
            )
          end

          let(:family) do
            family = FactoryBot.build(:family, person: primary)
            family.family_members = [
              FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent1),
              FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent2)
            ]

            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent1.id, kind: 'spouse')
            family.person.person_relationships.push PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
            family.save
            family
          end

          let(:dependent1) { FactoryBot.create(:person) }
          let(:dependent2) { FactoryBot.create(:person) }

          let(:yearly_expected_contribution) { 550.00 * 12 }

          let(:prev_slcsp_info) do
            OpenStruct.new(
              households: [
                OpenStruct.new(
                  household_id: primary_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: primary_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                ),
                OpenStruct.new(
                  household_id: dependents_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: dependent2_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                )
              ]
            )
          end

          let(:slcsp_info) do
            OpenStruct.new(
              households: [
                OpenStruct.new(
                  household_id: primary_aptc_grant.tax_household_id,
                  household_benchmark_ehb_premium: dependent1_benchmark_premium,
                  members: family.family_members.collect do |fm|
                    OpenStruct.new(
                      family_member_id: fm.id.to_s,
                      relationship_with_primary: fm.primary_relationship,
                      date_of_birth: fm.dob,
                      age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
                    )
                  end
                )
              ]
            )
          end

          let(:primary_benchmark_premium) { 500.00 }
          let(:dependent1_benchmark_premium) { 450.00 }
          let(:dependent2_benchmark_premium) { 350.00 }

          let(:yearly_expected_contribution1) { 300.00 * 12 }
          let(:yearly_expected_contribution2) { 100.00 * 12 }

          context 'with coinciding enrollment' do
            let!(:prev_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                elected_aptc_pct: 1.0,
                                enrollment_members: [primary_applicant, dependents[1]],
                                family: family,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                applied_aptc_amount: 450.00,
                                aasm_state: 'coverage_selected')
            end

            let(:hbx_enrollment) do
              FactoryBot.create(:hbx_enrollment,
                                :individual_shopping,
                                :with_silver_health_product,
                                :with_enrollment_members,
                                enrollment_members: dependents,
                                effective_on: TimeKeeper.date_of_record.beginning_of_month,
                                family: family)
            end

            before do
              allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
                double('IdentifySlcspWithPediatricDentalCosts',
                       call: double(:value! => prev_slcsp_info, :success? => true)),
                double('IdentifySlcspWithPediatricDentalCosts',
                       call: double(:value! => slcsp_info, :success? => true))
              )
            end

            it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
              prev_result = Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: prev_enrollment, effective_on: prev_enrollment.effective_on })
              expect(prev_result.success?).to eq true
              expect(prev_result.value!).to eq 450
              expect(result.success?).to eq true
              expect(result.value!).to eq 450
            end
          end
        end
      end
    end
  end

  context 'shopping with 5 member family' do
    let(:primary) { FactoryBot.create(:person) }
    let(:dependent_b) { FactoryBot.create(:person) }
    let(:dependent_c) { FactoryBot.create(:person) }
    let(:dependent_d) { FactoryBot.create(:person) }
    let(:dependent_e) { FactoryBot.create(:person) }

    let(:family) do
      family = FactoryBot.build(:family, person: primary)
      family.family_members = [
        FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent_b),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent_c),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent_d),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent_e)
      ]

      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent_b.id, kind: 'spouse')
      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent_c.id, kind: 'child')
      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent_d.id, kind: 'child')
      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent_e.id, kind: 'child')
      family.save
      family
    end

    let(:primary_applicant) { family.primary_applicant }
    let(:dependents) { family.dependents }

    let(:dependent_d_fm) do
      dependents.select {|dependent| dependent.person_id == dependent_d.id }.first
    end

    let(:other_dependents) do
      dependents.reject {|dependent| dependent.person_id == dependent_d.id }
    end

    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      determination
    end

    let(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household),
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let(:primary_tax_household) do
      tax_household_group.tax_households.first
    end

    let(:dependents_tax_household) do
      tax_household_group.tax_households.second
    end

    let(:primary_aptc_grant) { eligibility_determination.reload.grants.first }
    let(:dependents_aptc_grant) { eligibility_determination.reload.grants.second }

    let!(:primary_grant) do
      eligibility_determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution1,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: ([primary_applicant.id.to_s] + other_dependents.map(&:id).map(&:to_s)).flatten,
        tax_household_id: primary_tax_household.id
      )
    end

    let!(:dependents_grant) do
      eligibility_determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution2,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: [dependent_d_fm.id.to_s],
        tax_household_id: dependents_tax_household.id
      )
    end

    # let(:yearly_expected_contribution) { 200.00 * 12 }
    let(:yearly_expected_contribution1) { 200.00 * 12 }
    let(:yearly_expected_contribution2) { 100.00 * 12 }

    let(:primary_benchmark_premium) { 500.00 }
    let(:dependent_b_benchmark_premium) { 400.00 }
    let(:dependent_c_benchmark_premium) { 300.00 }
    let(:dependent_d_benchmark_premium) { 200.00 }
    let(:dependent_e_benchmark_premium) { 100.00 }

    let(:slcsp_info1) do
      OpenStruct.new(
        households: [
          OpenStruct.new(
            household_id: primary_aptc_grant.tax_household_id,
            household_benchmark_ehb_premium: 900.00,
            members: family.family_members.collect do |fm|
              OpenStruct.new(
                family_member_id: fm.id.to_s,
                relationship_with_primary: fm.primary_relationship,
                date_of_birth: fm.dob,
                age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
              )
            end
          ),
          OpenStruct.new(
            household_id: dependents_aptc_grant.tax_household_id,
            household_benchmark_ehb_premium: 200.00,
            members: family.family_members.collect do |fm|
              OpenStruct.new(
                family_member_id: fm.id.to_s,
                relationship_with_primary: fm.primary_relationship,
                date_of_birth: fm.dob,
                age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
              )
            end
          )
        ]
      )
    end

    let(:slcsp_info2) do
      OpenStruct.new(
        households: [
          OpenStruct.new(
            household_id: primary_aptc_grant.tax_household_id,
            household_benchmark_ehb_premium: 300.00,
            members: family.family_members.collect do |fm|
              OpenStruct.new(
                family_member_id: fm.id.to_s,
                relationship_with_primary: fm.primary_relationship,
                date_of_birth: fm.dob,
                age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
              )
            end
          )
        ]
      )
    end

    let(:slcsp_info3) do
      OpenStruct.new(
        households: [
          OpenStruct.new(
            household_id: primary_aptc_grant.tax_household_id,
            household_benchmark_ehb_premium: 100.00,
            members: family.family_members.collect do |fm|
              OpenStruct.new(
                family_member_id: fm.id.to_s,
                relationship_with_primary: fm.primary_relationship,
                date_of_birth: fm.dob,
                age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
              )
            end
          )
        ]
      )
    end

    context 'with coinciding enrollment' do
      let(:enrollment1) do
        FactoryBot.create(:hbx_enrollment,
                          :individual_shopping,
                          :with_silver_health_product,
                          :with_enrollment_members,
                          elected_aptc_pct: 0.9,
                          enrollment_members: ([primary_applicant] + [family.dependents.select { |dependent| [dependent_b.id, dependent_d.id].include? dependent.person_id }]).flatten,
                          family: family,
                          effective_on: TimeKeeper.date_of_record.beginning_of_month,
                          aasm_state: 'coverage_selected')
      end

      let(:enrollment2) do
        FactoryBot.create(:hbx_enrollment,
                          :individual_shopping,
                          :with_silver_health_product,
                          :with_enrollment_members,
                          elected_aptc_pct: 0.85,
                          enrollment_members: family.dependents.select { |dependent| [dependent_b.id, dependent_c.id, dependent_d.id].include? dependent.person_id },
                          family: family,
                          effective_on: TimeKeeper.date_of_record.beginning_of_month,
                          aasm_state: 'coverage_selected')
      end

      let(:enrollment3) do
        FactoryBot.create(:hbx_enrollment,
                          :individual_shopping,
                          :with_silver_health_product,
                          :with_enrollment_members,
                          elected_aptc_pct: 1.0,
                          enrollment_members: family.dependents.select { |dependent| [dependent_b.id, dependent_d.id, dependent_e.id].include? dependent.person_id },
                          family: family,
                          effective_on: TimeKeeper.date_of_record.beginning_of_month,
                          aasm_state: 'coverage_selected')
      end

      before do
        allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
          double('IdentifySlcspWithPediatricDentalCosts',
                 call: double(:value! => slcsp_info1, :success? => true)),
          double('IdentifySlcspWithPediatricDentalCosts',
                 call: double(:value! => slcsp_info2, :success? => true)),
          double('IdentifySlcspWithPediatricDentalCosts',
                 call: double(:value! => slcsp_info3, :success? => true))
        )
      end

      it 'returns sum of difference of benchmark premiums and monthly_expected_contribution as total available aptc of all tax household groups' do
        enr1_result = Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: enrollment1, effective_on: enrollment1.effective_on })
        expect(enr1_result.success?).to eq true
        expect(enr1_result.value!).to eq 800

        enr2_result = Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: enrollment2, effective_on: enrollment2.effective_on })
        expect(enr2_result.success?).to eq true
        expect(enr2_result.value!).to eq 300

        enr3_result = Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: enrollment3, effective_on: enrollment3.effective_on })
        expect(enr3_result.success?).to eq true
        expect(enr3_result.value!).to eq 100
      end
    end

    context 'having cents in contribution values' do
      let(:yearly_expected_contribution1) { 200.45 * 12 }
      let(:yearly_expected_contribution2) { 100.45 * 12 }

      let(:enrollment1) do
        FactoryBot.create(:hbx_enrollment,
                          :individual_shopping,
                          :with_silver_health_product,
                          :with_enrollment_members,
                          elected_aptc_pct: 0.9,
                          effective_on: TimeKeeper.date_of_record.beginning_of_month,
                          enrollment_members: ([primary_applicant] + [family.dependents.select { |dependent| [dependent_b.id, dependent_d.id].include? dependent.person_id }]).flatten,
                          family: family,
                          aasm_state: 'coverage_selected')
      end

      before do
        allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
          double('IdentifySlcspWithPediatricDentalCosts',
                 call: double(:value! => slcsp_info1, :success? => true))
        )
      end

      it 'returns sum of each grant aptc value after rounding' do
        enr1_result = Operations::PremiumCredits::FindAptc.new.call({ hbx_enrollment: enrollment1, effective_on: enrollment1.effective_on })
        expect(enr1_result.success?).to eq true
        expect(enr1_result.value!).to eq 800
      end
    end
  end
end
