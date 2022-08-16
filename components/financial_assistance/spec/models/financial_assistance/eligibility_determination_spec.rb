# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::EligibilityDetermination, type: :model, dbclean: :after_each do
  let(:family_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
  let!(:ed1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: ed1.id, application: application, family_member_id: BSON::ObjectId.new) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: ed1.id, application: application, family_member_id: BSON::ObjectId.new) }

  describe '#aptc_applicants' do
    it 'returns only aptc_eligible applicants' do
      applicant1.update_attributes!(is_ia_eligible: true)
      expect(ed1.aptc_applicants).to match([applicant1])
    end
  end

  describe '#medicaid_or_chip_applicants' do
    it 'returns only medicaid_or_chip_eligible applicants' do
      applicant1.update_attributes!(is_medicaid_chip_eligible: true)
      expect(ed1.medicaid_or_chip_applicants).to match([applicant1])
    end
  end

  describe '#uqhp_applicants' do
    it 'returns only uqhp_eligible applicants' do
      applicant1.update_attributes!(is_without_assistance: true)
      expect(ed1.uqhp_applicants).to match([applicant1])
    end
  end

  describe '#ineligible_applicants' do
    it 'returns only ineligible applicants' do
      applicant1.update_attributes!(is_totally_ineligible: true)
      expect(ed1.ineligible_applicants).to match([applicant1])
    end
  end

  describe '#applicants_with_non_magi_reasons' do
    it 'returns only eligible_for_non_magi_reasons applicants' do
      applicant2.update_attributes!(is_eligible_for_non_magi_reasons: true)
      expect(application.applicants_with_non_magi_reasons).to match([applicant2])
    end
  end
end
