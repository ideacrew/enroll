# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Relationship, type: :model, dbclean: :after_each do
  let(:bson_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:application, family_id: bson_id) }
  let!(:applicant1) { FactoryBot.create(:applicant, application: application, family_member_id: bson_id, is_primary_applicant: true) }
  let!(:applicant2) { FactoryBot.create(:applicant, application: application, family_member_id: bson_id) }

  let(:valid_params) do
    { kind: relationship_kind,
      applicant_id: applicant1.id,
      relative_id: applicant2.id }
  end

  describe '.Constants' do
    let(:class_constants)  { described_class.constants }
    let(:ui_rel_kinds) do
      if EnrollRegistry.feature_enabled?(:mitc_relationships)
        [
          'spouse',
          'domestic_partner',
          'child',
          'parent',
          'sibling',
          'unrelated',
          'aunt_or_uncle',
          'nephew_or_niece',
          'grandchild',
          'grandparent',
          'father_or_mother_in_law',
          'daughter_or_son_in_law',
          'brother_or_sister_in_law',
          'cousin',
          'domestic_partners_child',
          'parents_domestic_partner'
        ]
      else
        ['spouse',
         'domestic_partner',
         'child',
         'parent',
         'sibling',
         'unrelated',
         'aunt_or_uncle',
         'nephew_or_niece',
         'grandchild',
         'grandparent']
      end
    end

    it 'should have relationships for UI display as a constant' do
      expect(class_constants.include?(:RELATIONSHIPS_UI)).to be_truthy
      expect(described_class::RELATIONSHIPS_UI).to eq(ui_rel_kinds)
    end
  end

  describe 'domestic_partners_child, parents_domestic_partner' do
    let!(:person2) { FactoryBot.create(:person) }
    let(:relationship_kind) { ['domestic_partners_child', 'parents_domestic_partner'].sample }

    context 'persistance' do
      it 'should behave based on config for mitc_relationships' do
        if EnrollRegistry.feature_enabled?(:mitc_relationships)
          expect do
            application.relationships.create!(valid_params)
          end.not_to raise_error
        else
          expect do
            application.relationships.create!(valid_params)
          end.to raise_error(Mongoid::Errors::Validations, /Validation of FinancialAssistance::Relationship failed/)
        end
      end
    end

    context 'constants' do
      context 'RELATIONSHIPS' do
        it 'should behave based on config for mitc_relationships' do
          if EnrollRegistry.feature_enabled?(:mitc_relationships)
            expect(described_class::RELATIONSHIPS).to include(relationship_kind)
          else
            expect(described_class::RELATIONSHIPS).not_to include(relationship_kind)
          end
        end
      end

      context 'RELATIONSHIPS_UI' do
        it 'should behave based on config for mitc_relationships' do
          if EnrollRegistry.feature_enabled?(:mitc_relationships)
            expect(described_class::RELATIONSHIPS_UI).to include(relationship_kind)
          else
            expect(described_class::RELATIONSHIPS_UI).not_to include(relationship_kind)
          end
        end
      end
    end
  end
end
