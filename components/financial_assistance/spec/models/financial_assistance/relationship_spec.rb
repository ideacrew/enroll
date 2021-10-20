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

    it 'should have years to renew range constant' do
      expect(class_constants.include?(:RELATIONSHIPS_UI)).to be_truthy
      expect(described_class::RELATIONSHIPS_UI).to eq([
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
        'cousin'
      ])
    end
  end

  describe 'persist relationship' do
    context 'with valid params for father_or_mother_in_law' do
      let(:relationship_kind) { 'father_or_mother_in_law' }

      before do
        application.relationships << described_class.new(valid_params)
      end

      it 'should create a valid relationship' do
        expect(application.valid?).to be_truthy
      end
    end

    context 'with valid params for daughter_or_son_in_law' do
      let(:relationship_kind) { 'daughter_or_son_in_law' }

      before do
        application.relationships << described_class.new(valid_params)
      end

      it 'should create a valid relationship' do
        expect(application.valid?).to be_truthy
      end
    end

    context 'with valid params for brother_or_sister_in_law' do
      let(:relationship_kind) { 'brother_or_sister_in_law' }

      before do
        application.relationships << described_class.new(valid_params)
      end

      it 'should create a valid relationship' do
        expect(application.valid?).to be_truthy
      end
    end

    context 'with valid params for cousin' do
      let(:relationship_kind) { 'cousin' }

      before do
        application.relationships << described_class.new(valid_params)
      end

      it 'should create a valid relationship' do
        expect(application.valid?).to be_truthy
      end

      it 'should return relationship kind of applicant' do
        expect(application.relationships.first.kind).to eq('cousin')
      end
    end
  end
end
