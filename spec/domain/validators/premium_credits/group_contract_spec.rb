# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::PremiumCredits::GroupContract, type: :model, dbclean: :after_each do
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
      {
        kind: 'aptc_csr',
        authority_determination_id: BSON::ObjectId.new,
        authority_determination_class: 'FinancialAssistance::Application',
        premium_credit_monthly_cap: 317.0,
        sub_group_id: BSON::ObjectId.new,
        sub_group_class: 'FinancialAssistance::EligibilityDetermination',
        start_on: start_of_month,
        member_premium_credits: [
          { kind: 'aptc_eligible', value: 'true', start_on: start_of_month, family_member_id: family.primary_applicant.id },
          { kind: 'csr', value: '73', start_on: start_of_month, family_member_id: family.primary_applicant.id }
        ]
      }
    end

    it 'should return success' do
      expect(result.success?).to be_truthy
    end
  end

  context 'invalid member_premium_credits' do
    let(:params) do
      {
        kind: 'aptc_csr',
        authority_determination_id: BSON::ObjectId.new,
        authority_determination_class: 'FinancialAssistance::Application',
        premium_credit_monthly_cap: 317.0,
        sub_group_id: BSON::ObjectId.new,
        sub_group_class: 'FinancialAssistance::EligibilityDetermination',
        start_on: start_of_month,
        member_premium_credits: [
          { kind: "kind", value: 'true', start_on: start_of_month, family_member_id: family.primary_applicant.id },
          { kind: 'csr', value: 73, start_on: start_of_month, family_member_id: family.primary_applicant.id }
        ]
      }
    end

    it 'should return failure with errors' do
      expect(result.errors.to_h).to eq(
        { member_premium_credits: { 0 => [{ text: 'invalid member_premium_credit', error: { kind: ['must be one of: aptc_eligible, csr'] } }],
                                    1 => [{ text: 'invalid member_premium_credit', error: { value: ['must be a string'] } }] } }
      )
    end
  end

  context 'invalid group_premium_credit' do
    let(:params) do
      {
        kind: 'kind',
        authority_determination_id: BSON::ObjectId.new,
        authority_determination_class: 'FinancialAssistance::Application',
        premium_credit_monthly_cap: 317.0,
        sub_group_id: BSON::ObjectId.new,
        sub_group_class: 'FinancialAssistance::EligibilityDetermination',
        start_on: start_of_month,
        member_premium_credits: [
          { kind: 'aptc_eligible', value: 'true', start_on: start_of_month, family_member_id: family.primary_applicant.id },
          { kind: 'csr', value: '73', start_on: start_of_month, family_member_id: family.primary_applicant.id }
        ]
      }
    end

    it 'should return failure with errors' do
      expect(result.errors.to_h).to eq({ kind: ["must be one of: aptc_csr"] })
    end
  end
end
