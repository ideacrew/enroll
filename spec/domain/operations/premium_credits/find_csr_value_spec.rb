# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindCsrValue, dbclean: :after_each do

  let(:result) { subject.call(params) }

  context 'invalid params' do
    context 'missing group_premium_credits' do
      let(:params) do
        { group_premium_credits: nil }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Invalid params. missing group_premium_credits')
      end
    end

    context 'missing year' do
      let(:params) do
        { group_premium_credits: [GroupPremiumCredit.new] }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing family member ids')
      end
    end
  end

  context 'valid params' do
    let(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:group_premium_credit1) { FactoryBot.create(:group_premium_credit, family: family)}
    let!(:group_premium_credit2) { FactoryBot.create(:group_premium_credit, family: family)}

    let(:group_premium_credits) do
      result = ::Operations::PremiumCredits::FindAll.new.call({ family: family, year: TimeKeeper.date_of_record.year, kind: 'aptc_csr' })
      result.value!
    end


    let(:params) do
      { group_premium_credits: group_premium_credits, family_member_ids: family.family_members.map(&:id) }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_0'
    end

    context 'indian_tribe_member' do
      let(:person) { FactoryBot.create(:person, indian_tribe_member: true)}

      context 'is_ia_eligible' do
        let!(:member_premium_credits1) do
          [family.primary_applicant].collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit1, is_ia_eligible: true, family_member_id: family_member.id, kind: 'csr', value: '73')
          end
        end

        let!(:member_premium_credits2) do
          (family.family_members - [family.primary_applicant]).collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit2, is_ia_eligible: true, family_member_id: family_member.id, kind: 'csr', value: '73')
          end
        end

        it 'returns csr_limited' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 'csr_limited'
        end
      end

      context 'non is_ia_eligible' do

        let!(:member_premium_credits1) do
          [family.primary_applicant].collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit1, is_ia_eligible: false, family_member_id: family_member.id, kind: 'csr', value: '73')
          end
        end

        let!(:member_premium_credits2) do
          (family.family_members - [family.primary_applicant]).collect do |family_member|
            FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit2, is_ia_eligible: false, family_member_id: family_member.id, kind: 'csr', value: '73')
          end
        end

        it 'returns csr_0' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 'csr_0'
        end
      end
    end
  end
end
