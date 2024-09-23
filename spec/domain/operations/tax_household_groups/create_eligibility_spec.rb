# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::TaxHouseholdGroups::CreateEligibility, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'invalid params' do

    let(:params) do
      {}
    end

    it 'should return failure' do
      result = subject.call(params)
      expect(result.failure?).to eq true
    end
  end

  describe 'valid params' do
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

    it 'should create grants' do
      subject.call(params)
      eligibility_determination = family.reload.eligibility_determination

      expect(eligibility_determination.grants.size).to eq 2
    end
  end

  describe '#call' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

    let(:spouse_person) do
      per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
      person.ensure_relationship_with(per, 'spouse')
      per
    end

    let(:child_person) do
      per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
      person.ensure_relationship_with(per, 'child')
      per
    end

    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:spouse_member) { FactoryBot.create(:family_member, family: family, person: spouse_person, is_active: spouse_member_active) }
    let(:child_member) { FactoryBot.create(:family_member, family: family, person: child_person) }

    let(:params) do
      { family: spouse_member.family, th_group_info: {} }
    end

    context 'with:
      - none of the active family members are applying for coverage
      - spouse_member is applying for coverage but is a destroyed member(not an active family member)
    ' do

      let(:spouse_member_active) { false }

      before do
        child_member.person.consumer_role.update_attributes(is_applying_coverage: false)
        person.consumer_role.update_attributes(is_applying_coverage: false)
      end

      it 'returns a failure monad' do
        expect(subject.call(params).failure).to eq(l10n('create_eligibility_tool.no_members_applying_coverage'))
      end
    end
  end
end
