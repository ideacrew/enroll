# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::PremiumCredits::MemberContract, type: :model, dbclean: :after_each do
  let(:result) { subject.call(params) }
  let(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '1179388',
                      last_name: 'Eric',
                      first_name: 'Pierpont',
                      dob: '1984-05-22')
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:start_of_month) { TimeKeeper.date_of_record.beginning_of_month }

  context 'valid params' do
    let(:params) do
      { kind: 'aptc_eligible', value: 'true', start_on: start_of_month, family_member_id: family.primary_applicant.id }
    end

    it 'should return success' do
      expect(result.success?).to be_truthy
    end
  end

  context 'invalid kind' do
    let(:params) do
      { kind: 'kind', value: 'true', start_on: start_of_month, family_member_id: family.primary_applicant.id }
    end

    it 'should return failure with errors' do
      expect(result.errors.to_h).to eq({ kind: ['must be one of: aptc_eligible, csr'] })
    end
  end
end
