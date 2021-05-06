# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::ApplicationFactory, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let!(:applicant2) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 10.years,
                      family_member_id: BSON::ObjectId.new)
  end

  context 'duplicate' do

    context 'Should not create relationships for duplicate/new application if there are no relationship for application.' do
      before do
        factory = described_class.new(application)
        @duplicate_application = factory.duplicate
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.count).to eq 0
      end
    end

    context 'Should create relationships for duplicate/new application with applicants from new application.' do
      before do
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant2.id, relative_id: applicant.id, kind: "child")
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant.id, relative_id: applicant2.id, kind: "parent")
        factory = described_class.new(application)
        @duplicate_application = factory.duplicate
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.pluck(:relative_id)).to eq @duplicate_application.applicants.pluck(:id)
      end
    end
  end
end
