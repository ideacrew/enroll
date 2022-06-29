# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberPremiumCredit, type: :model do
  let(:person)      { FactoryBot.create(:person, :with_consumer_role) }
  let(:family)      { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:primary_fm)  { family.primary_family_member }
  let(:group_pc)    { FactoryBot.create(:group_premium_credit, family: family) }

  let(:params) do
    { kind: 'aptc_eligible',
      value: 'true',
      start_on: TimeKeeper.date_of_record }
  end

  describe 'initialize' do
    subject { described_class.new(input_params) }

    context 'valid params' do
      let(:input_params) { params }

      it 'should be valid' do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'invalid kind' do
      let(:input_params) { params.merge({ kind: 'test' }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Kind test is not a valid member premium credit kind')
      end
    end

    context 'invalid kind' do
      let(:input_params) { params.merge({ end_on: TimeKeeper.date_of_record - 1.day }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include("end_on: #{input_params[:end_on]} cannot occur before start_on: #{input_params[:start_on]}")
      end
    end

    context 'invalid value for kind aptc_eligible' do
      let(:input_params) { params.merge({ value: '87' }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          "value: 87 is not a valid value for kind: aptc_eligible, should be one of #{MemberPremiumCredit::APTC_VALUES}"
        )
      end
    end

    context 'invalid value for kind csr' do
      let(:input_params) { params.merge({ value: 'true', kind: 'csr' }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          "value: true is not a valid value for kind: csr, should be one of #{MemberPremiumCredit::CSR_VALUES}"
        )
      end
    end
  end

  describe 'scopes' do
    let!(:member_pc1) do
      FactoryBot.create(:member_premium_credit,
                        family_member_id: primary_fm.id,
                        group_premium_credit: group_pc)
    end

    let!(:member_pc2) do
      FactoryBot.create(:member_premium_credit,
                        :csr_eligible,
                        family_member_id: primary_fm.id,
                        group_premium_credit: group_pc)
    end

    context 'aptc_eligible' do
      it 'should only return member_pc1' do
        expect(
          group_pc.member_premium_credits.aptc_eligible.pluck(:id)
        ).to eq([member_pc1.id])
      end
    end

    context 'csr_eligible' do
      it 'should only return member_pc2' do
        expect(
          group_pc.member_premium_credits.csr_eligible.pluck(:id)
        ).to eq([member_pc2.id])
      end
    end
  end

end
