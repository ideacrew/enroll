# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Applicant, type: :model, dbclean: :after_each do

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: 'draft',
                      effective_date: Date.today)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: Date.today - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  context 'i766' do
    context 'valid i766 document exists' do
      before do
        applicant.update_attributes({vlp_subject: 'I-766 (Employment Authorization Card)',
                                     alien_number: '1234567890',
                                     card_number: 'car1234567890',
                                     expiration_date: Date.today})
      end

      it 'should return true for i766' do
        expect(applicant.reload.i766).to eq(true)
      end
    end

    context 'invalid i766 document' do
      it 'should return false for i766' do
        expect(applicant.i766).to eq(false)
      end
    end
  end

  context '#relationship_kind_with_primary' do
    let!(:application) do
      FactoryBot.create(:application,
                        family_id: BSON::ObjectId.new,
                        aasm_state: 'draft',
                        effective_date: Date.today)
    end

    let!(:parent_applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 40.years,
                        is_primary_applicant: true,
                        family_member_id: BSON::ObjectId.new)
    end

    let!(:spouse_applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 30.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    let!(:child_applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 10.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    before do
      application.ensure_relationship_with_primary(child_applicant, 'child')
      application.ensure_relationship_with_primary(spouse_applicant, 'spouse')
    end

    it 'should return correct relationship kind' do
      expect(parent_applicant.relationship_kind_with_primary).to eq 'self'
      expect(spouse_applicant.relationship_kind_with_primary).to eq 'spouse'
      expect(child_applicant.relationship_kind_with_primary).to eq 'child'
    end
  end

  context 'enrolled_or_eligible_in_any_medicare' do
    context 'with enrolled medicare benefits' do
      before do
        applicant.benefits << FinancialAssistance::Benefit.new({title: 'Financial Benefit',
                                                                kind: 'is_enrolled',
                                                                insurance_kind: ['medicare', 'medicare_advantage', 'medicare_part_b'].sample,
                                                                start_on: Date.today})
        applicant.save!
      end

      it 'should return true enrolled_or_eligible_in_any_medicare?' do
        expect(applicant.enrolled_or_eligible_in_any_medicare?).to eq(true)
      end
    end

    context 'without any enrolled medicare benefits' do
      it 'should return false' do
        expect(applicant.enrolled_or_eligible_in_any_medicare?).to eq(false)
      end
    end
  end

  context 'when IAP applicant is destroyed' do
    context 'should destroy their relationships of the applicants' do
      let!(:spouse_applicant) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 30.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      let!(:child_applicant) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 10.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end
      before do
        application.ensure_relationship_with_primary(spouse_applicant, 'spouse')
        application.ensure_relationship_with_primary(child_applicant, 'child')
        application.update_or_build_relationship(child_applicant, spouse_applicant, 'child')
        application.update_or_build_relationship(spouse_applicant, child_applicant, 'parent')
      end

      it 'when spouse applicant is deleted it should delete their relationships' do
        expect(application.applicants.count).to eq 3
        expect(application.relationships.count).to eq 6
        applicant_spouse = application.applicants.where(id: spouse_applicant.id)
        expect(applicant_spouse.count).to eq 1
        applicant_spouse.destroy_all
        expect(applicant_spouse.count).to eq 0
        expect(application.applicants.count).to eq 2
        expect(application.relationships.count).to eq 2
      end
    end
  end
end
