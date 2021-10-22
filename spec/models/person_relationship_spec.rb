require 'rails_helper'

describe PersonRelationship, dbclean: :after_each do
  it { should validate_presence_of :relative_id }
  it { should validate_presence_of :kind }

  let(:kind) {"spouse"}
  let!(:person) { FactoryBot.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789") }

  describe "class methods" do
    context "shop_display_relationship_kinds" do
      let(:shop_kinds) {["spouse", "domestic_partner", "child", ""]}
    end
  end

  describe ".new" do
    let(:valid_params) do
      { kind: kind,
        relative: person,
        person: person
      }
    end

    let(:consumer_relationship_kinds) { [
        "self",
        "spouse",
        "domestic_partner",
        "child",
        "parent",
        "sibling",
        "ward",
        "guardian",
        "unrelated",
        "other_tax_dependent",
        "aunt_or_uncle",
        "nephew_or_niece",
        "grandchild",
        "grandparent"
      ] }

    let(:kinds) {  [
      "spouse",
      "life_partner",
      "child",
      "adopted_child",
      "annuitant",
      "aunt_or_uncle",
      "brother_or_sister_in_law",
      "collateral_dependent",
      "court_appointed_guardian",
      "daughter_or_son_in_law",
      "dependent_of_a_minor_dependent",
      "father_or_mother_in_law",
      "foster_child",
      "grandchild",
      "grandparent",
      "great_grandchild",
      "great_grandparent",
      "guardian",
      "nephew_or_niece",
      "other_relationship",
      "parent",
      "sibling",
      "sponsored_dependent",
      "stepchild",
      "stepparent",
      "trustee",
      "unrelated",
      "ward",
      'cousin'
    ] }

    describe 'domestic_partners_child, parents_domestic_partner' do
      let!(:person2) { FactoryBot.create(:person) }
      let(:rel_kinds) { ['domestic_partners_child', 'parents_domestic_partner'] }

      context 'persistance' do
        it 'should behave based on config for mitc_relationship' do
          if EnrollRegistry.feature_enabled?(:mitc_relationships)
            expect do
              person.person_relationships.create!(relative_id: person2.id, kind: rel_kinds.sample)
            end.not_to raise_error
          else
            expect do
              person.person_relationships.create!(relative_id: person2.id, kind: rel_kinds.sample)
            end.to raise_error(Mongoid::Errors::Validations, /is not a valid person relationship/)
          end
        end
      end

      context 'constants' do
        context 'Relationships' do
          it 'should behave based on config for mitc_relationship' do
            if EnrollRegistry.feature_enabled?(:mitc_relationships)
              expect(described_class::Relationships).to include(rel_kinds.sample)
            else
              expect(described_class::Relationships).not_to include(rel_kinds.sample)
            end
          end
        end

        context 'Relationships_UI' do
          it 'should behave based on config for mitc_relationship' do
            if EnrollRegistry.feature_enabled?(:mitc_relationships)
              expect(described_class::Relationships_UI).to include(rel_kinds.sample)
            else
              expect(described_class::Relationships_UI).not_to include(rel_kinds.sample)
            end
          end
        end
      end
    end

    context "consumer relationship dropdown list(family member page)" do
      let(:params){ valid_params.deep_merge!({kind: "other_tax_dependent"}) }

      it "consumer relationships should be matched" do
        expect(BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS).to eq consumer_relationship_kinds
      end

      it "consumer relationships displayed on UI should match" do
        expect(BenefitEligibilityElementGroup::Relationships_UI - ['self']).to eq PersonRelationship::Relationships_UI
      end

      it "should be valid if kind is present in person_relationship" do
        expect(PersonRelationship.new(**params).valid?).to be_truthy
      end
    end

    it "relationships should be sorted" do
      expect(PersonRelationship::Relationships).to eq kinds unless EnrollRegistry.feature_enabled?(:mitc_relationships)
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(PersonRelationship.new(**params).save).to be_falsey
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:kind)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:kind].any?).to be_truthy
      end
    end

    context "with no relative" do
      let(:params) {valid_params.except(:relative)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:relative_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      it "should save" do
        expect(PersonRelationship.new(**params).save).to be_truthy
      end
    end

    context "with all valid kinds" do
      let(:params) {valid_params}
      it "should save" do
        kinds.each do |rkind|
          params[:kind] = rkind
          expect(PersonRelationship.new(**params).save).to be_truthy
        end
      end
    end
  end

  describe 'create valid relationship' do
    let!(:person2) { FactoryBot.create(:person) }
    let(:valid_params) do
      { kind: relative_kind,
        relative: person,
        person: person2 }
    end

    context 'valid params with father_or_mother_in_law' do
      let(:relative_kind) { 'father_or_mother_in_law' }

      before do
        person.person_relationships << described_class.new(valid_params)
        person.save!
      end

      it 'should return valid person' do
        expect(person.valid?).to be_truthy
      end

      it 'should return relationship kind of person' do
        expect(person.person_relationships.first.kind).to eq('father_or_mother_in_law')
      end
    end

    context 'valid params with daughter_or_son_in_law' do
      let(:relative_kind) { 'daughter_or_son_in_law' }

      before do
        person.person_relationships << described_class.new(valid_params)
        person.save!
      end

      it 'should return valid person' do
        expect(person.valid?).to be_truthy
      end

      it 'should return relationship kind of person' do
        expect(person.person_relationships.first.kind).to eq('daughter_or_son_in_law')
      end
    end

    context 'valid params with brother_or_sister_in_law' do
      let(:relative_kind) { 'brother_or_sister_in_law' }

      before do
        person.person_relationships << described_class.new(valid_params)
        person.save!
      end

      it 'should return valid person' do
        expect(person.valid?).to be_truthy
      end

      it 'should return relationship kind of person' do
        expect(person.person_relationships.first.kind).to eq('brother_or_sister_in_law')
      end
    end

    context 'valid params with cousin' do
      let(:relative_kind) { 'cousin' }

      before do
        person.person_relationships << described_class.new(valid_params)
        person.save!
      end

      it 'should return valid person' do
        expect(person.valid?).to be_truthy
      end

      it 'should return relationship kind of person' do
        expect(person.person_relationships.first.kind).to eq('cousin')
      end
    end
  end
end
