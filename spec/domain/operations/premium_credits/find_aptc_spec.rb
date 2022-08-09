# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindAptc, dbclean: :after_each do

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
      context 'without no group premium credits for family' do

        let(:person) { FactoryBot.create(:person) }
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: family.family_members, family: family)}

        it 'returns zero available aptc' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 0.0
        end
      end

      context 'when enrolled members does not have a group_premium_credits' do
        let(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person) }
        let(:person) { FactoryBot.create(:person) }
        let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: [family.primary_applicant], family: family)}
        let(:non_primary_fm) { family.family_members.detect { |family_member| !family_member.is_primary_applicant? && family_member.is_active? } }
        let(:group_premium_credit) { FactoryBot.create(:group_premium_credit, family: family)}
        let!(:member_premium_credit) { FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit, is_ia_eligible: true, family_member_id: non_primary_fm.id)}

        it 'returns zero available aptc' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 0.0
        end
      end
    end

    context 'eligible for aptc' do
      context 'with single group_premium_credit' do
        let(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person) }
        let(:person) { FactoryBot.create(:person) }
        let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: family.family_members, family: family)}
        let(:group_premium_credit) { FactoryBot.create(:group_premium_credit, family: family, premium_credit_monthly_cap: premium_credit_monthly_cap)}
        let!(:member_premium_credits) do
          family.family_members.collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit, is_ia_eligible: true, family_member_id: family_member.id)
          end
        end

        let(:premium_credit_monthly_cap) { 1000.00 }

        context 'without any non enrolled family member' do

          it 'returns total premium_credit_monthly_cap as available aptc' do
            expect(result.success?).to eq true
            expect(result.value!).to eq premium_credit_monthly_cap
          end
        end

        context 'with non enrolled family member' do
          context 'with current active enrollment' do
            let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: [family.primary_applicant], family: family)}

            context 'with zero applied aptc on current enrollment' do
              let!(:current_hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, enrollment_members: (family.family_members - [family.primary_applicant]), family: family)}

              it 'returns total premium_credit_monthly_cap as available aptc' do
                expect(result.success?).to eq true
                expect(result.value!).to eq premium_credit_monthly_cap
              end
            end

            context 'with applied aptc on current enrollment' do
              let(:applied_premium_credit) { 100.0 }
              let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: family.family_members, family: family)}

              context 'new enrollment replacing existing enrollment' do
                let!(:current_hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, enrollment_members: family.family_members, family: family, applied_premium_credit: applied_premium_credit) }

                it 'returns total premium_credit_monthly_cap as available aptc' do
                  expect(result.success?).to eq true
                  expect(result.value!).to eq premium_credit_monthly_cap
                end
              end

              context 'new enrollment without replacing existing enrollment' do
                let!(:current_hbx_enrollment) do
                  FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, enrollment_members: (family.family_members - [family.primary_applicant]), family: family, applied_premium_credit: applied_premium_credit)
                end

                it 'returns by removing current applied premium on enrollment from total premium_credit_monthly_cap as available aptc' do
                  expect(result.success?).to eq true
                  expect(result.value!).to eq premium_credit_monthly_cap - 100.0
                end
              end
            end
          end

          context 'without any current active enrollment' do
            let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: [family.primary_applicant], family: family)}
            let(:non_enrolling_family_members) { family.family_members - [family.primary_applicant] }
            let(:benchmark_premiums) do
              family.family_members.inject({}) do |result, family_member|
                result[family_member.id] = {
                  premium: 300.00
                }
                result
              end
            end

            let(:non_enrolled_members_bp) do
              non_enrolling_family_members.reduce(0) do |_sum, member|
                benchmark_premiums[member.id][:premium]
              end
            end

            before do
              subject.instance_variable_set(:@benchmark_premiums, benchmark_premiums)
            end

            it 'returns by removing benchmark premium of non enrolling family_members from premium_credit_monthly_cap as available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq(premium_credit_monthly_cap - non_enrolled_members_bp)
            end
          end

          context 'when ehb premium is less than available aptc' do
            before do
              allow(hbx_enrollment).to receive(:total_ehb_premium).and_return premium_credit_monthly_cap - 100.0
            end

            it 'returns total ehb premium as available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq premium_credit_monthly_cap - 100.0
            end
          end
        end
      end

      context 'with multiple group_premium_credits' do
        let(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person) }
        let(:person) { FactoryBot.create(:person) }
        let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: family.family_members, family: family)}
        let(:group_premium_credit1) { FactoryBot.create(:group_premium_credit, family: family, premium_credit_monthly_cap: premium_credit_monthly_cap_1)}
        let(:non_enrolling_family_members) { family.family_members - [family.primary_applicant] }
        let!(:member_premium_credits1) do
          [family.primary_applicant, non_enrolling_family_members[0]].collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit1, is_ia_eligible: true, family_member_id: family_member.id)
          end
        end

        let(:group_premium_credit2) { FactoryBot.create(:group_premium_credit, family: family, premium_credit_monthly_cap: premium_credit_monthly_cap_2)}
        let!(:member_premium_credits2) do
          [non_enrolling_family_members[1]].collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit2, is_ia_eligible: true, family_member_id: family_member.id)
          end
        end

        let(:premium_credit_monthly_cap_1) { 1200.00 }
        let(:premium_credit_monthly_cap_2) { 800.00 }

        context 'without any non enrolled family member' do

          it 'returns sum of all premium_credit_monthly_cap as available aptc' do
            expect(result.success?).to eq true
            expect(result.value!).to eq(premium_credit_monthly_cap_1 + premium_credit_monthly_cap_2)
          end
        end

        context 'with non enrolled family member' do
          context 'with current active enrollment' do
            let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: [family.primary_applicant], family: family)}
            let!(:current_hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, enrollment_members: (family.family_members - [family.primary_applicant]), family: family)}

            it 'returns premium_credit_monthly_cap of respective premium credit as available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq premium_credit_monthly_cap_1
            end
          end

          context 'without any current active enrollment' do
            let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :individual_shopping, :with_enrollment_members, enrollment_members: [family.primary_applicant], family: family)}

            let(:benchmark_premiums) do
              family.family_members.inject({}) do |result, family_member|
                result[family_member.id] = {
                  premium: 300.00
                }
                result
              end
            end

            let(:non_enrolled_members_bp) do
              benchmark_premiums[non_enrolling_family_members[1].id][:premium]
            end

            before do
              subject.instance_variable_set(:@benchmark_premiums, benchmark_premiums)
            end

            it 'returns by removing benchmark premium of non enrolling family_members from premium_credit_monthly_cap as available aptc' do
              expect(result.success?).to eq true
              expect(result.value!).to eq(premium_credit_monthly_cap_1 - non_enrolled_members_bp)
            end
          end
        end
      end
    end
  end
end
