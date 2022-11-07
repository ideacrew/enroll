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

  context 'without eligibility_determination' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    let(:params) do
      { family_member_ids: [family.primary_applicant.id], family: family, year: TimeKeeper.date_of_record.year }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_0'
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
          value: '87',
          start_on: TimeKeeper.date_of_record.beginning_of_year,
          end_on: TimeKeeper.date_of_record.end_of_year,
          assistance_year: TimeKeeper.date_of_record.year,
          member_ids: family.family_members.map(&:id)
        )
      end

      determination
    end


    let(:params) do
      { family_member_ids: [family.primary_applicant.id], family: family, year: TimeKeeper.date_of_record.year }
    end

    it 'returns success' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_87'
    end

    context 'indian_tribe_member' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, tribal_id: BSON::ObjectId.new) }

      it 'returns csr_limited' do
        expect(result.success?).to eq true
        expect(result.value!).to eq 'csr_limited'
      end
    end
  end

  # One member with AI/AN and other non AI/AN member
  context 'family members with subject, with eligibility_state, without CSR grants' do
    let!(:person10) { FactoryBot.create(:person, :with_consumer_role, tribal_id: BSON::ObjectId.new)}
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let!(:family_member) do
      per = FactoryBot.create(:person, :with_consumer_role)
      person10.ensure_relationship_with(per, 'spouse')
      FactoryBot.create(:family_member, family: family10, person: per)
    end
    let!(:eligibility_determination) do
      determination = family10.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      family10.family_members.each do |family_member|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )
        subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
      end

      determination
    end

    let(:params) do
      { family_member_ids: family10.family_members.map(&:id), family: family10, year: TimeKeeper.date_of_record.year }
    end

    it 'should return csr value as csr_0' do
      expect(result.success?).to eq true
      expect(result.value!).to eq 'csr_0'
    end
  end

  context 'native_american_csr indian_tribe_member' do
    let(:person10) { FactoryBot.create(:person, :with_consumer_role, tribal_id: BSON::ObjectId.new)}
    let(:family10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let(:second_csr) { '0' }

    let(:eligibility_determination) do
      determination = family10.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      family10.family_members.each_with_index do |family_member, ind|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
        state.grants.create(
          key: "CsrAdjustmentGrant",
          value: ind.zero? ? '100' : second_csr,
          start_on: TimeKeeper.date_of_record.beginning_of_year,
          end_on: TimeKeeper.date_of_record.end_of_year,
          assistance_year: TimeKeeper.date_of_record.year,
          member_ids: family10.family_members.map(&:id)
        )
      end

      determination
    end

    let(:family_member) do
      per = FactoryBot.create(:person, :with_consumer_role)
      person10.ensure_relationship_with(per, 'spouse')
      FactoryBot.create(:family_member, family: family10, person: per)
    end

    let(:params) do
      { family_member_ids: family10.family_members.map(&:id), family: family10, year: TimeKeeper.date_of_record.year }
    end

    context 'one family member without subject' do
      it 'should return csr value as csr_limited' do
        expect(result.success?).to eq true
        expect(result.value!).to eq 'csr_limited'
      end
    end

    context 'one family member with subject' do
      before { eligibility_determination }

      it 'should return csr value as csr_100' do
        expect(result.success?).to eq true
        expect(result.value!).to eq 'csr_100'
      end
    end

    context 'two family members without subjects' do
      before { family_member }

      it 'should return csr value as csr_0' do
        expect(result.value!).to eq 'csr_0'
      end
    end

    context 'two family members with subjects, dependent with csr 0' do
      let(:second_csr) { '0' }

      before do
        family_member
        eligibility_determination
      end

      it 'should return csr value as csr_0' do
        expect(result.value!).to eq 'csr_0'
      end
    end

    context 'two family members, primary with subject' do
      let(:second_csr) { '100' }

      before do
        family_member
        eligibility_determination
      end

      it 'should return csr value as csr_100' do
        expect(result.value!).to eq 'csr_100'
      end
    end
  end
end
