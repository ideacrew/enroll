# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindCsrValue, dbclean: :after_each do

  let(:result) { subject.call(params) }

  context 'invalid params' do
    context 'missing family' do
      let(:params) do
        { family: nil }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Invalid params. group_premium_credit should be an instance of Group Premium Credit')
      end
    end

    context 'missing year' do
      let(:params) do
        { group_premium_credit: GroupPremiumCredit.new }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing family member ids')
      end
    end
  end

  context 'valid params' do
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:group_premium_credit) { FactoryBot.create(:group_premium_credit, family: family)}

    let(:params) do
      { group_premium_credit: group_premium_credit, family_member_ids: family.family_members.map(&:id) }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_0'
    end

    context 'indian_tribe_member' do
      let(:person) { FactoryBot.create(:person, indian_tribe_member: true)}

      context 'is_ia_eligible' do
        let!(:member_premium_credit) { FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit, is_ia_eligible: true)}

        it 'returns csr_limited' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 'csr_limited'
        end
      end

      context 'non is_ia_eligible' do
        let!(:member_premium_credit) { FactoryBot.create(:member_premium_credit, group_premium_credit: group_premium_credit, is_ia_eligible: false)}

        it 'returns csr_0' do
          expect(result.success?).to eq true
          expect(result.value!).to eq 'csr_0'
        end
      end
    end
  end
end
