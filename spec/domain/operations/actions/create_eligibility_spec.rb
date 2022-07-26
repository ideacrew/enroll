# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::Actions::CreateEligibility, type: :model, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  context 'with APTC eligible members' do
    let(:input_params) do
      {
        "person_id" => person.id.to_s,
        "family_actions_id" => "family_actions_#{family.id}",
        "max_aptc" => "300.00",
        "csr" => "94",
        "effective_date" => TimeKeeper.date_of_record.strftime,
        "family_members" => {
          person.hbx_id.to_s => {
            "pdc_type" => "is_ia_eligible", "reason" => ""
          }
        }
      }.with_indifferent_access
    end

    it 'should return Family with group premium credits' do
      expect(subject.call(input_params).success).to be_a(Family)
      expect(family.reload.group_premium_credits.count).to eq(1)
      expect(family.group_premium_credits.first.member_premium_credits.count).to eq(2)
    end
  end

  context 'with Medicaid eligible members' do
    let(:input_params) do
      {
        "person_id" => person.id.to_s,
        "family_actions_id" => "family_actions_#{family.id}",
        "max_aptc" => "300.00",
        "csr" => "94",
        "effective_date" => TimeKeeper.date_of_record.strftime,
        "family_members" => {
          person.hbx_id.to_s => {
            "pdc_type" => "is_medicaid_chip_eligible", "reason" => ""
          }
        }
      }.with_indifferent_access
    end

    it 'should return Family without group premium credits' do
      expect(subject.call(input_params).success).to be_a(Family)
      expect(family.reload.group_premium_credits.count).to eq(0)
    end
  end
end
