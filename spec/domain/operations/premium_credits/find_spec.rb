# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::Find, dbclean: :after_each do

  let(:result) { subject.call(params) }

  context 'invalid params' do
    context 'missing family' do
      let(:params) do
        { family: nil }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Invalid params. family should be an instance of Family')
      end
    end

    context 'missing year' do
      let(:params) do
        { family: Family.new }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing year')
      end
    end

    context 'missing kind' do
      let(:params) do
        { family: Family.new, year: TimeKeeper.date_of_record.year }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing kind')
      end
    end
  end

  context 'valid params' do
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:group_premium_credit) { FactoryBot.create(:group_premium_credit, family: family)}

    let(:params) do
      { family: Family.new, year: TimeKeeper.date_of_record.year, kind: 'aptc_csr' }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq group_premium_credit
    end
  end
end
