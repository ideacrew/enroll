# frozen_string_literal: true

require "rails_helper"

describe Forms::HealthcareForChildcareProgramForm do

  context '.load_eligibility' do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary)}

    let(:eligibility_params) do
      {
        evidence_key: :osse_subsidy,
        evidence_value: true,
        effective_date: ::TimeKeeper.date_of_record
      }
    end

    before do
      allow(::EnrollRegistry).to receive(:feature?).and_return(true)
      allow(::EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    end

    context 'with consumer role' do
      let(:primary) { FactoryBot.create(:person, :with_consumer_role) }

      before do
        primary.consumer_role.create_eligibility(eligibility_params)
      end

      it 'should return eligibility' do
        expect(subject.osse_eligibility).to be_blank
        expect(subject.role).to be_blank

        subject.load_eligibility(primary)

        expect(subject.osse_eligibility).to be_truthy
        expect(subject.role).to eq(primary.consumer_role)
      end
    end

    context 'when both consumer and resident role present' do
      let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_resident_role) }

      before do
        primary.resident_role.create_eligibility(eligibility_params)
      end

      it 'should return eligibility with resident role' do
        expect(subject.osse_eligibility).to be_blank
        expect(subject.role).to be_blank

        subject.load_eligibility(primary)

        expect(subject.osse_eligibility).to be_truthy
        expect(subject.role).to eq(primary.resident_role)
      end
    end
  end

  context '.build_forms_for' do
    let(:primary) { FactoryBot.create(:person, :with_consumer_role) }
    let(:spouse) { FactoryBot.create(:person, :with_consumer_role) }
    let(:child1) { FactoryBot.create(:person, :with_consumer_role) }

    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary)}
    let!(:family_member_spouse) { FactoryBot.create(:family_member, person: spouse, family: family)}
    let!(:family_member_child1) { FactoryBot.create(:family_member, person: child1, family: family)}

    it 'should build form objects for all active members' do
      forms = described_class.build_forms_for(family)
      expect(forms.keys.count).to eq family.active_family_members.count

      family.active_family_members.each do |fm|
        expect(forms.key?(fm.person)).to be_truthy
        expect(forms[fm.person]).to be_an_instance_of(described_class)
      end
    end
  end

  context '.submit_with' do
    let(:primary) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary)}

    let(:params) do
      {
        person_id: primary.id,
        osse_eligibility: osse_eligibility
      }
    end

    let(:start_on) { ::TimeKeeper.date_of_record }

    before do
      allow(::EnrollRegistry).to receive(:feature?).and_return(true)
      allow(::EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    end

    context 'when osse_eligibility selected YES' do
      let(:osse_eligibility) { 'true' }

      it 'should create osse eligibility' do
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_falsey
        described_class.submit_with(params)

        primary.reload
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_truthy
      end
    end

    context 'when osse_eligibility selected NO' do
      let(:osse_eligibility) { 'false' }

      before do
        primary.consumer_role.create_eligibility({
                                                   evidence_key: :osse_subsidy,
                                                   evidence_value: true,
                                                   effective_date: start_on
                                                 })
      end

      it 'should terminate osse eligibility' do
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_truthy
        described_class.submit_with(params)
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_falsey
      end
    end

    context 'when both consumer and resident role present' do
      let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_resident_role) }
      let(:osse_eligibility) { 'true' }

      it 'should create eligibility with resident role' do
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_falsey
        expect(primary.resident_role.osse_eligible?(start_on)).to be_falsey

        described_class.submit_with(params)

        primary.reload
        expect(primary.consumer_role.osse_eligible?(start_on)).to be_falsey
        expect(primary.resident_role.osse_eligible?(start_on)).to be_truthy
      end
    end
  end
end
