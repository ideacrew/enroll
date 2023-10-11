# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Family, dbclean: :around_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:spouse) { FactoryBot.create(:person)}

  context "valid person relationship" do
    let!(:person_relationship) do
      person.person_relationships.build(relative: spouse, kind: "spouse")
      person.save
    end

    context "#build_family_member" do
      before do
        @family_member = family.build_family_member(spouse)
      end
      it "should build family member" do
        expect(@family_member).to be_a(FamilyMember)
      end

      it "should not be persisted" do
        expect(@family_member).to_not be_persisted
      end

      it "should build coverage_household member" do
        coverage_household = family.active_household.coverage_households.first
        coverage_household_member = coverage_household.coverage_household_members.where(family_member_id: @family_member.id).first
        expect(coverage_household_member.present?).to be_truthy
        expect(coverage_household_member).to_not be_persisted
      end
    end

  end

  context "invalid person relationship" do
    context "#build_family_member" do
      before do
        @family_member = family.build_family_member(spouse)
      end
      it "should build family member" do
        expect(@family_member).to be_a(FamilyMember)
      end

      it "should not be persisted" do
        expect(@family_member).to_not be_persisted
      end

      it "should build coverage_household member" do
        immediate_family_coverage_household = family.active_household.immediate_family_coverage_household
        coverage_household_member = immediate_family_coverage_household.coverage_household_members.where(family_member_id: @family_member.id).first
        expect(coverage_household_member.present?).to be_falsey
      end
    end
  end
end