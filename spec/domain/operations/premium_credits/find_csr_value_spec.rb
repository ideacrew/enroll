# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::FindCsrValue, dbclean: :after_each do

  let(:result) { subject.call(params) }

  context 'invalid params' do
    context 'missing family_member_ids' do
      let(:params) do
        { family_member_ids: nil }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing family member ids')
      end
    end

    context 'missing family' do
      let(:params) do
        { family_member_ids: [BSON::ObjectId.new] }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing family')
      end
    end

    context 'missing year' do
      let(:params) do
        { family_member_ids: [BSON::ObjectId.new], family: Family.new }
      end

      it 'returns failure' do
        expect(result.failure?).to eq true
        expect(result.failure).to eq('Missing year')
      end
    end
  end

  context 'valid params' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      family.family_members.each do |family_member|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
        state.grants.create(
          key: "CsrAdjustmentGrant",
          value: '0',
          start_on: TimeKeeper.date_of_record.beginning_of_year,
          end_on: TimeKeeper.date_of_record.end_of_year,
          assistance_year: TimeKeeper.date_of_record.year,
          member_ids: family.family_members.map(&:id)
        )
      end

      determination
    end


    let(:params) do
      { family_member_ids: [family.primary_applicant.id.to_s], family: family, year: TimeKeeper.date_of_record.year }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_0'
    end

    context 'indian_tribe_member' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, tribal_id: BSON::ObjectId.new) }

      it 'returns csr_limited' do
        expect(result.success?).to eq true
        expect(result.value!).to eq 'csr_limited'
      end
    end
  end
end
