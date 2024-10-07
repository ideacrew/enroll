# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applicants::CorrectEthnicityAndTribeCodes do
  describe '#call' do
    let(:person1) do
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        ethnicity: applicant1_ethnicity,
        tribe_codes: applicant1_tribe_codes
      )
    end

    let(:family1) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }
    let(:primary_applicant1) { family1.primary_applicant }
    let(:application1) { FactoryBot.create(:financial_assistance_application, family: family1) }

    let(:applicant1) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application1,
        person_hbx_id: person1.hbx_id,
        family_member_id: primary_applicant1.id,
        ethnicity: applicant1_ethnicity,
        tribe_codes: applicant1_tribe_codes
      )
    end

    let(:person2) do
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        ethnicity: applicant2_ethnicity,
        tribe_codes: applicant2_tribe_codes
      )
    end

    let(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }
    let(:primary_applicant2) { family2.primary_applicant }
    let(:application2) { FactoryBot.create(:financial_assistance_application, family: family2) }

    let(:applicant2) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application2,
        person_hbx_id: person2.hbx_id,
        family_member_id: primary_applicant2.id,
        ethnicity: applicant2_ethnicity,
        tribe_codes: applicant2_tribe_codes
      )
    end

    let(:applicant1_ethnicity) { ['ethnicity1'] }
    let(:applicant1_tribe_codes) { ['tribeee'] }
    let(:applicant2_ethnicity) { ['ethnicity2'] }
    let(:applicant2_tribe_codes) { ['triibee'] }

    before do
      applicant1
      applicant2
    end

    context 'when:
      - there are applicants with nil ethnicity' do
      let(:applicant1_ethnicity) { nil }

      it 'updates applicant1 only' do
        subject.call
        expect(applicant1.reload.ethnicity).to eq([])
        expect(applicant1.tribe_codes).to eq(applicant1_tribe_codes)
        expect(applicant2.reload.ethnicity).to eq(applicant2_ethnicity)
        expect(applicant2.tribe_codes).to eq(applicant2_tribe_codes)
      end
    end

    context 'when:
      - there are applicants with nil tribe_codes' do
      let(:applicant1_tribe_codes) { nil }

      it 'updates applicant2 only' do
        subject.call
        expect(applicant1.reload.ethnicity).to eq(applicant1_ethnicity)
        expect(applicant1.tribe_codes).to eq([])
        expect(applicant2.reload.ethnicity).to eq(applicant2_ethnicity)
        expect(applicant2.tribe_codes).to eq(applicant2_tribe_codes)
      end
    end

    context 'when:
      - there are applicants with nil values for ethnicity
      - there are applicants with nil values for tribe_codes' do
      let(:applicant1_tribe_codes) { nil }
      let(:applicant2_ethnicity) { nil }

      it 'updates applicant2 only' do
        subject.call
        expect(applicant1.reload.ethnicity).to eq(applicant1_ethnicity)
        expect(applicant1.tribe_codes).to eq([])
        expect(applicant2.reload.ethnicity).to eq([])
        expect(applicant2.tribe_codes).to eq(applicant2_tribe_codes)
      end
    end

    context 'when:
      - there are applicants with nil values for both ethnicity and tribe_codes' do
      let(:applicant1_ethnicity) { nil }
      let(:applicant1_tribe_codes) { nil }

      it 'updates applicant2 only' do
        subject.call
        expect(applicant1.reload.ethnicity).to eq([])
        expect(applicant1.tribe_codes).to eq([])
        expect(applicant2.reload.ethnicity).to eq(applicant2_ethnicity)
        expect(applicant2.tribe_codes).to eq(applicant2_tribe_codes)
      end
    end
  end
end
