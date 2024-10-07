# frozen_string_literal: true

RSpec.describe Operations::Migrations::People::CorrectEthnicityAndTribeCodes do

  describe '#call' do
    let(:person1) do
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        ethnicity: person1_ethnicity,
        tribe_codes: person1_tribe_codes
      )
    end

    let(:person2) do
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        ethnicity: person2_ethnicity,
        tribe_codes: person2_tribe_codes
      )
    end

    let(:person1_ethnicity) { ['ethnicity1'] }
    let(:person1_tribe_codes) { ['tribeee'] }
    let(:person2_ethnicity) { ['ethnicity2'] }
    let(:person2_tribe_codes) { ['triibee'] }

    before do
      person1
      person2
    end

    context 'when:
      - there are people with nil ethnicity' do
      let(:person1_ethnicity) { nil }

      it 'updates person1 only' do
        subject.call
        expect(person1.reload.ethnicity).to eq([])
        expect(person1.tribe_codes).to eq(person1_tribe_codes)
        expect(person2.reload.ethnicity).to eq(person2_ethnicity)
        expect(person2.tribe_codes).to eq(person2_tribe_codes)
      end
    end

    context 'when:
      - there are people with nil tribe_codes' do
      let(:person2_tribe_codes) { nil }

      it 'updates person2 only' do
        subject.call
        expect(person1.reload.ethnicity).to eq(person1_ethnicity)
        expect(person1.tribe_codes).to eq(person1_tribe_codes)
        expect(person2.reload.ethnicity).to eq(person2_ethnicity)
        expect(person2.tribe_codes).to eq([])
      end
    end

    context 'when:
      - there are people with nil values for ethnicity
      - there are people with nil values for tribe_codes' do
      let(:person1_tribe_codes) { nil }
      let(:person2_ethnicity) { nil }

      it 'updates person2 only' do
        subject.call
        expect(person1.reload.ethnicity).to eq(person1_ethnicity)
        expect(person1.tribe_codes).to eq([])
        expect(person2.reload.ethnicity).to eq([])
        expect(person2.tribe_codes).to eq(person2_tribe_codes)
      end
    end

    context 'when:
      - there are people with nil values for both ethnicity and tribe_codes' do
      let(:person1_ethnicity) { nil }
      let(:person1_tribe_codes) { nil }

      it 'updates person2 only' do
        subject.call
        expect(person1.reload.ethnicity).to eq([])
        expect(person1.tribe_codes).to eq([])
        expect(person2.reload.ethnicity).to eq(person2_ethnicity)
        expect(person2.tribe_codes).to eq(person2_tribe_codes)
      end
    end
  end
end
