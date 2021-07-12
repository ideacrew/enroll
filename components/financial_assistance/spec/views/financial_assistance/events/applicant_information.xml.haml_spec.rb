# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'components/financial_assistance/app/views/financial_assistance/events/_applicant_information.xml.haml' do
  context 'conditional data elements' do

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

    context 'foster care questions' do

      context 'applicant not applying for coverage' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).not_to match(/is_former_foster_care/)}
        it {expect(rendered).not_to match(/age_left_foster_care/)}
        it {expect(rendered).not_to match(/foster_care_us_state/)}
        it {expect(rendered).not_to match(/had_medicaid_during_foster_care/)}
      end

      context 'applicant is not in is_former_foster_care' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: true, is_former_foster_care: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).to match(/is_former_foster_care/)}
        it {expect(rendered).not_to match(/age_left_foster_care/)}
        it {expect(rendered).not_to match(/foster_care_us_state/)}
        it {expect(rendered).not_to match(/had_medicaid_during_foster_care/)}
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

        it {expect(rendered).to match(/is_former_foster_care/)}
        it {expect(rendered).to match(/age_left_foster_care/)}
        it {expect(rendered).to match(/foster_care_us_state/)}
        it {expect(rendered).to match(/had_medicaid_during_foster_care/)}
      end
    end

    context 'student questions' do

      context 'applicant not applying for coverage' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).not_to match(/is_student/)}
        it {expect(rendered).not_to match(/student_type/)}
        it {expect(rendered).not_to match(/school_type/)}
        it {expect(rendered).not_to match(/student_status_end_on/)}
      end

      context 'applicant is not a student' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: true, is_student: false)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).to match(/is_student/)}
        it {expect(rendered).not_to match(/student_type/)}
        it {expect(rendered).not_to match(/school_type/)}
        it {expect(rendered).not_to match(/student_status_end_on/)}
      end

      context 'applicant is a student' do
        before :each do
          applicant.update_attributes!(is_applying_coverage: true,
                                       is_student: true,
                                       student_kind: 'full_time',
                                       student_school_kind: 'high_school',
                                       student_status_end_on: Date.today.strftime('%m/%d/%Y'))
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it {expect(rendered).to match(/is_student/)}
        it {expect(rendered).to match(/student_type/)}
        it {expect(rendered).to match(/school_type/)}
        it {expect(rendered).to match(/student_status_end_on/)}
      end
    end

    context 'is_medicare_eligible' do
      before do
        applicant.update_attributes(has_enrolled_health_coverage: true)
        applicant.benefits << FinancialAssistance::Benefit.new({title: 'Financial Benefit', kind: 'is_enrolled', insurance_kind: 'medicare', start_on: Date.today})
        applicant.save!
        render 'financial_assistance/events/applicant_information', applicant: applicant
      end

      it 'should include is_medicare_eligible tag with true as answer' do
        expect(rendered).to include("<is_medicare_eligible>true</is_medicare_eligible>")
      end
    end

    context 'is_self_attested_blind' do
      context 'with tag' do
        before do
          applicant.update_attributes(is_self_attested_blind: false, is_applying_coverage: true)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should include is_self_attested_blind tag' do
          expect(rendered).to include("<is_self_attested_blind>false</is_self_attested_blind>")
        end
      end

      context 'without tag' do
        before do
          applicant.update_attributes(is_self_attested_blind: nil)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should not include is_self_attested_blind tag' do
          expect(rendered).not_to include("<is_self_attested_blind>")
        end
      end
    end

    context 'has_daily_living_help' do
      context 'with tag' do
        before do
          applicant.update_attributes(has_daily_living_help: false, is_applying_coverage: true)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should include has_daily_living_help tag' do
          expect(rendered).to include("<has_daily_living_help>false</has_daily_living_help>")
        end
      end

      context 'without tag' do
        before do
          applicant.update_attributes(has_daily_living_help: nil)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should not include has_daily_living_help tag' do
          expect(rendered).not_to include("<has_daily_living_help>")
        end
      end
    end

    context 'has_bill_pay_3_month_help' do
      context 'with tag' do
        before do
          applicant.update_attributes(need_help_paying_bills: false, is_applying_coverage: true)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should include has_bill_pay_3_month_help tag' do
          expect(rendered).to include("<has_bill_pay_3_month_help>false</has_bill_pay_3_month_help>")
        end
      end

      context 'without tag' do
        before do
          applicant.update_attributes(need_help_paying_bills: nil)
          render 'financial_assistance/events/applicant_information', applicant: applicant
        end

        it 'should not include has_bill_pay_3_month_help tag' do
          expect(rendered).not_to include("<has_bill_pay_3_month_help>")
        end
      end
    end
  end
end
