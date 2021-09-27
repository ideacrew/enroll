# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Applicant, type: :model, dbclean: :after_each do

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: 'draft',
                      assistance_year: TimeKeeper.date_of_record.year,
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

  context '#is_eligible_for_non_magi_reasons' do
    it 'should return a field on applicant model' do
      expect(applicant.is_eligible_for_non_magi_reasons).to eq(nil)
    end
  end

  context 'current_month_incomes' do
    let!(:create_job_income1) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    let!(:income2) do
      inc = ::FinancialAssistance::Income.new({ kind: 'net_self_employment',
                                                frequency_kind: 'monthly',
                                                amount: 100.00,
                                                start_on: TimeKeeper.date_of_record.next_month.beginning_of_month })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      @incomes = applicant.reload.current_month_incomes
    end

    it 'should return only one income' do
      expect(@incomes.count).to eq(1)
    end

    it 'should return the income of kind wages_and_salaries' do
      expect(@incomes.first.kind).to eq('wages_and_salaries')
    end

    it 'should not return the income of kind net_self_employment' do
      expect(@incomes.first.kind).not_to eq('net_self_employment')
    end
  end

  context 'current_month_incomes with income that started previous year and no end date' do
    let!(:create_job_income12) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.prev_year,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      @incomes = applicant.reload.current_month_incomes
    end

    it 'should return only one income' do
      expect(@incomes.count).to eq(1)
    end

    it 'should return the income of kind wages_and_salaries' do
      expect(@incomes.first.kind).to eq('wages_and_salaries')
    end
  end

  context 'current_month_incomes with income that started in March & End Dated in August' do
    let!(:create_job_income12) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      @incomes = applicant.reload.current_month_incomes
    end

    it 'should return only one income' do
      expect(@incomes.count).to eq(1)
    end

    it 'should return the income of kind wages_and_salaries' do
      expect(@incomes.first.kind).to eq('wages_and_salaries')
    end
  end

  context 'current_month_incomes with income that started previous year and ended last month' do
    let!(:create_job_income11) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.prev_year,
                                                end_on: TimeKeeper.date_of_record.prev_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      @incomes = applicant.reload.current_month_incomes
    end

    it 'should not return any incomes as the income ended last month' do
      expect(@incomes.count).to be_zero
    end
  end

  context 'total_hours_worked_per_week' do
    let!(:create_job_income12) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.prev_year,
                                                end_on: TimeKeeper.date_of_record.prev_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    context 'income end_on is before TimeKeeper.date_of_record' do
      it 'should return 0' do
        expect(applicant.total_hours_worked_per_week).to be_zero
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

  context '#is_eligible_for_non_magi_reasons' do
    it 'should return a field on applicant model' do
      expect(applicant.is_eligible_for_non_magi_reasons).to eq(nil)
    end
  end

  context 'is_csr_73_87_or_94' do
    before do
      applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: [73, 87, 94].sample })
    end

    it 'should return true' do
      expect(applicant.reload.is_csr_73_87_or_94?).to be_truthy
    end
  end

  context 'is_csr_100' do
    before do
      applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: 100 })
    end

    it 'should return true' do
      expect(applicant.reload.is_csr_100?).to be_truthy
    end
  end

  context 'is_csr_limited' do
    context 'aqhp' do
      before do
        applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: -1 })
      end

      it 'should return true' do
        expect(applicant.reload.is_csr_limited?).to be_truthy
      end
    end

    context 'uqhp' do
      before do
        applicant.update_attributes!({ indian_tribe_member: true })
      end

      it 'should return true' do
        expect(applicant.reload.is_csr_limited?).to be_truthy
      end
    end
  end

  context '#tax_info_complete?' do
    before do
      applicant.update_attributes({is_required_to_file_taxes: true,
                                   is_joint_tax_filing: false,
                                   is_claimed_as_tax_dependent: false})
    end

    context 'is_filing_as_head_of_household feature disabled' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:filing_as_head_of_household).and_return(false)
      end

      it 'should return true without is_filing_as_head_of_household' do
        expect(applicant.tax_info_complete?).to eq true
      end
    end

    context 'is_filing_as_head_of_household feature enabled' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:filing_as_head_of_household).and_return(true)
      end

      it 'should return false without is_filing_as_head_of_household' do
        expect(applicant.tax_info_complete?).to eq false
      end

      it 'should return true with is_filing_as_head_of_household' do
        applicant.update_attributes({is_filing_as_head_of_household: true})
        expect(applicant.tax_info_complete?).to eq true
      end
    end
  end

  context '#other_questions_complete?' do
    context 'pregnancy_due_on' do
      before do
        applicant.update_attributes!({
                                       is_pregnant: true,
                                       children_expected_count: 1,
                                       pregnancy_due_on: nil,
                                       is_applying_coverage: true,
                                       is_physically_disabled: false
                                     })
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(true)
      end

      context 'pregnancy_due_on_required feature disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(false)
        end

        it 'should return true without pregnancy_due_on_required' do
          expect(applicant.other_questions_complete?).to eq true
        end
      end

      context 'pregnancy_due_on_required feature enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(true)
        end

        it 'should return false without pregnancy_due_on_required' do
          expect(applicant.other_questions_complete?).to eq false
        end
      end
    end

    context 'is_physically_disabled' do
      before do
        applicant.update_attributes!({
                                       is_pregnant: true,
                                       children_expected_count: 1,
                                       pregnancy_due_on: nil,
                                       is_applying_coverage: true,
                                       is_physically_disabled: nil
                                     })
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(false)
      end

      context 'question_required feature disabled' do
        it 'should return true without is_physically_disabled' do
          expect(applicant.other_questions_complete?).to eq true
        end
      end

      context 'question_required feature enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(true)
        end

        it 'should return false without is_physically_disabled' do
          expect(applicant.other_questions_complete?).to eq false
        end
      end
    end
  end
end
