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
  end
end
