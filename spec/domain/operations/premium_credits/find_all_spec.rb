# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindAll, dbclean: :after_each do

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
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }

    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: 500.00,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: family.family_members.map(&:id)
      )

      determination
    end

    let(:params) do
      { family: family, year: TimeKeeper.date_of_record.year, kind: 'AdvancePremiumAdjustmentGrant' }
    end

    it 'returns success & all group premium credits' do
      expect(result.success?).to eq true
      expect(result.value!.size).to eq 1
    end
  end
end
