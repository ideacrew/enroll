# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::ConditionalFieldsLookupFactory, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: "draft",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new,
                      is_student: true)
  end

  context 'conditionally displayable' do
    # student_kind, student_status_end_on and student_school_kind
    context 'student_kind with applicant aged 40 years' do
      before do
        @result = described_class.new('applicant', applicant.id, :student_kind).conditionally_displayable?
      end

      it 'should return true if the applicant is a student' do
        expect(@result).to eq(true)
      end
    end
  end
end
