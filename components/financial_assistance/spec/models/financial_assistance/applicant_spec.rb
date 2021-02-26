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
end
