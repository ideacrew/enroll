# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::TaxHouseholdGroups::CreateEligibility, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:params) do
    { family: family, th_group_info: tax_household_group.deep_symbolize_keys! }
  end

  let(:family) do
    family = FactoryBot.build(:family, person: primary)
    family.family_members = [
      FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
      FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent1),
      FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent2)
    ]

    family.person.person_relationships.push PersonRelationship.new(relative_id: dependent1.id, kind: 'spouse')
    family.person.person_relationships.push PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
    family.save
    family
  end

  let(:primary_fm) { family.primary_applicant }
  let(:dependents) { family.dependents }

  let(:primary) { FactoryBot.create(:person, :with_consumer_role) }
  let(:dependent1) { FactoryBot.create(:person, :with_consumer_role) }
  let(:dependent2) { FactoryBot.create(:person, :with_consumer_role) }

  let(:tax_household_group) do
    {
      "person_id" => primary.id.to_s,
      "family_actions_id" => "family_actions_#{family.id}",
      "effective_date" => TimeKeeper.date_of_record.to_s,
      "tax_households" => {
        "0" => {
          "members" => [
            {
              "pdc_type" => "is_ia_eligible",
              "csr" => "100",
              "is_filer" => "on",
              "member_name" => "Ivl ivl",
              "family_member_id" => primary_fm.id.to_s
            },
            {
              "pdc_type" => "is_ia_eligible",
              "csr" => "87",
              "is_filer" => nil,
              "member_name" => "Spouse spouse",
              "family_member_id" => dependents[0].id.to_s
            }
          ].to_json,
          "monthly_expected_contribution" => "400"
        },
        "1" => {
          "members" => [
            {
              "pdc_type" => "is_ia_eligible",
              "csr" => "94",
              "is_filer" => "on",
              "member_name" => "Child child",
              "family_member_id" => dependents[1].id.to_s
            }
          ].to_json,
          "monthly_expected_contribution" => "300"
        }
      }
    }
  end

  describe 'invalid params' do
    it 'should return failure' do
      params = {}
      result = subject.call(params)
      expect(result.failure?).to eq true
    end

    it 'should return error message' do
      family.family_members.each do |fm|
        fm.person.consumer_role.update_attributes!(is_applying_coverage: false)
      end
      result = subject.call(params)
      expect(result.failure?).to eq true
      expect(result.failure).to eq "The Create Eligibility tool cannot be used because the consumer is not applying for coverage."
    end
  end

  describe 'valid params' do


    it 'should create grants' do
      subject.call(params)
      eligibility_determination = family.reload.eligibility_determination

      expect(eligibility_determination.grants.size).to eq 2
    end
  end
end
