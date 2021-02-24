# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'components/financial_assistance/app/views/financial_assistance/events/_applicant_information.xml.haml' do
  context 'conditional data elements' do

    let!(:application) do
      FactoryBot.create(:application, family_id: BSON::ObjectId.new, aasm_state: "draft",effective_date: TimeKeeper.date_of_record)
    end
    let!(:applicant) do
      FactoryBot.create(:applicant, application: application, dob: TimeKeeper.date_of_record - 40.years, is_primary_applicant: true, family_member_id: BSON::ObjectId.new)
    end

    context 'foster care questions' do

      context 'applicant not applying for coverage' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).not_to match /is_former_foster_care/}
        it {expect(rendered).not_to match /age_left_foster_care/}
        it {expect(rendered).not_to match /foster_care_us_state/}
        it {expect(rendered).not_to match /had_medicaid_during_foster_care/}
      end

      context 'applicant is not in is_former_foster_care' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: true, is_former_foster_care: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).to match /is_former_foster_care/}
        it {expect(rendered).not_to match /age_left_foster_care/}
        it {expect(rendered).not_to match /foster_care_us_state/}
        it {expect(rendered).not_to match /had_medicaid_during_foster_care/}
      end

      context 'applicant is in is_former_foster_care' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: true,
                                       is_former_foster_care: true,
                                       age_left_foster_care: 15,
                                       foster_care_us_state: 'DC',
                                       had_medicaid_during_foster_care: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).to match /is_former_foster_care/}
        it {expect(rendered).to match /age_left_foster_care/}
        it {expect(rendered).to match /foster_care_us_state/}
        it {expect(rendered).to match /had_medicaid_during_foster_care/}
      end
    end
  end
end
