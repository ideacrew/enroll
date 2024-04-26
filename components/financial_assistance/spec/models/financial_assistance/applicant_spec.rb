# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Applicant, type: :model, dbclean: :after_each do

  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: 'draft',
                      assistance_year: TimeKeeper.date_of_record.year,
                      effective_date: Date.today)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      dob: Date.today - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let(:income) do
    income = FactoryBot.build(:financial_assistance_income)
    applicant.incomes << income
  end

  describe "scopes" do
    let!(:applicant2) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        dob: Date.today - 30.years,
                        family_member_id: BSON::ObjectId.new)
    end

    describe '.aptc_eligible' do
      it 'returns only aptc_eligible applicants' do
        applicant.update_attributes!(is_ia_eligible: true)
        expect(application.applicants.aptc_eligible).to match([applicant])
      end
    end

    describe '.medicaid_or_chip_eligible' do
      it 'returns only medicaid_or_chip_eligible applicants' do
        applicant.update_attributes!(is_medicaid_chip_eligible: true)
        expect(application.applicants.medicaid_or_chip_eligible).to match([applicant])
      end
    end

    describe '.uqhp_eligible' do
      it 'returns only uqhp_eligible applicants' do
        applicant.update_attributes!(is_without_assistance: true)
        expect(application.applicants.uqhp_eligible).to match([applicant])
      end
    end

    describe '.ineligible' do
      it 'returns only ineligible applicants' do
        applicant.update_attributes!(is_totally_ineligible: true)
        expect(application.applicants.ineligible).to match([applicant])
      end
    end

    describe '.eligible_for_non_magi_reasons' do
      it 'returns only eligible_for_non_magi_reasons applicants' do
        applicant.update_attributes!(is_eligible_for_non_magi_reasons: true)
        expect(application.applicants.eligible_for_non_magi_reasons).to match([applicant])
      end
    end
  end

  context "is primary caregiver" do
    it "should not have a default value" do
      expect(applicant.is_primary_caregiver).to be(nil)
    end
  end

  describe 'after_update' do
    context 'callbacks' do

      it 'calls propagate_applicant' do
        allow(applicant).to receive(:propagate_applicant).and_return(true)
        applicant.update_attributes(dob: Date.today - 30.years)
        expect(applicant).to have_received(:propagate_applicant)
      end
    end
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

  context 'format_citizen' do
    before do
      applicant.update_attributes({is_applying_coverage: false,
                                   citizen_status: "not_lawfully_present_in_us"})
    end

    context 'non-applicant member has not_lawfully_present_in_us citizen status' do
      context 'non_applicant_citizen_status feature is enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_applicant_citizen_status).and_return(true)
        end

        it 'should return N/A' do
          expect(applicant.format_citizen).to_not eq FinancialAssistance::Applicant::CITIZEN_KINDS[:not_lawfully_present_in_us]
        end
      end

      context 'non_applicant_citizen_status feature is disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_applicant_citizen_status).and_return(false)
        end

        it 'should return Not lawfully present in US' do
          expect(applicant.format_citizen).to eq FinancialAssistance::Applicant::CITIZEN_KINDS[:not_lawfully_present_in_us]
        end
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

    context 'primary is married and filing taxes' do
      let(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants) }
      let(:primary) { application.primary_applicant }
      let(:spouse) { application.applicants.at(1) }

      before do
        spouse.relationship = ('spouse')
      end

      context 'when is_joint_tax_filing is missing for primary and spouse' do
        it 'should return false for primary' do
          expect(primary.tax_info_complete?).to eq false
        end

        it 'should return false for spouse' do
          expect(spouse.tax_info_complete?).to eq false
        end
      end
    end
  end

  context 'is filing application with parents in household' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:filing_as_head_of_household).and_return(false)
      applicant.update_attributes({is_required_to_file_taxes: true,
                                   is_joint_tax_filing: false,
                                   is_claimed_as_tax_dependent: false,
                                   is_filing_as_head_of_household: false})
    end
    let!(:parent_applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 40.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    let!(:parent2_applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 40.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    let!(:applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 20.years,
                        is_primary_applicant: true,
                        family_member_id: BSON::ObjectId.new)
    end
    before do
      application.ensure_relationship_with_primary(parent_applicant, 'parent')
      application.ensure_relationship_with_primary(parent2_applicant, 'parent')
      application.update_or_build_relationship(parent2_applicant, parent_applicant, 'spouse')
      application.update_or_build_relationship(parent_applicant, parent2_applicant, 'spouse')
    end

    it "shouldn't require 'filing jointly' to be present" do
      expect(applicant.tax_info_complete_unmarried_child?).to eq true
    end
  end

  context '#other_questions_complete?' do
    context "when not applying for coverage, has_unemployment_income: nil and is_pregnant" do
      before do
        applicant.update_attributes!(has_unemployment_income: nil, pregnancy_due_on: TimeKeeper.date_of_record - 10.days, children_expected_count: 1, is_pregnant: true, is_applying_coverage: false)
      end

      it "return true for other_questions_complete?" do
        expect(applicant.other_questions_complete?).to be_truthy
      end

      it "return nil for post_partum period" do
        applicant.other_questions_complete?
        expect(applicant.is_post_partum_period).to eql(nil)
      end
    end

    context "when not applying for coverage and is not pregnant" do
      context "and other_questions_complete? is independent of has_unemployment_income" do
        [true, false, nil].each do |has_unemployment_income|
          before do
            applicant.update_attributes!(has_unemployment_income: has_unemployment_income, is_pregnant: false, is_applying_coverage: false)
          end

          it "return false for other_questions_complete?" do
            expect(applicant.other_questions_complete?).to be_falsey
          end

          it "return nil for post_partum period" do
            applicant.other_questions_complete?
            expect(applicant.is_post_partum_period).to eql(nil)
          end
        end
      end
    end

    context "when applying for coverage and is not pregnant" do
      context "and other_questions_complete? is independent of has_unemployment_income" do
        [true, false, nil].each do |has_unemployment_income|
          before do
            applicant.update_attributes!(has_unemployment_income: has_unemployment_income, is_pregnant: false, is_applying_coverage: true)
          end

          it "return false for other_questions_complete?" do
            expect(applicant.other_questions_complete?).to be_falsey
          end

          it "return nil for post_partum period" do
            applicant.other_questions_complete?
            expect(applicant.is_post_partum_period).to eql(nil)
          end
        end
      end
    end

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
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:no_ssn_reason_dropdown).and_return(false)
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

    context 'is_enrolled_on_medicaid' do
      before do
        applicant.update_attributes!({
                                       is_pregnant: false,
                                       is_applying_coverage: true,
                                       is_post_partum_period: true,
                                       pregnancy_end_on: TimeKeeper.date_of_record - 10.days,
                                       is_enrolled_on_medicaid: nil
                                     })
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:no_ssn_reason_dropdown).and_return(false)
      end

      context 'is_enrolled_on_medicaid feature disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:is_enrolled_on_medicaid).and_return(false)
        end

        it 'should return true without is_enrolled_on_medicaid' do
          expect(applicant.other_questions_complete?).to eq true
        end
      end

      context 'is_enrolled_on_medicaid feature enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:is_enrolled_on_medicaid).and_return(true)
        end

        it 'should return false without is_enrolled_on_medicaid' do
          expect(applicant.other_questions_complete?).to eq false
        end
      end
    end

    context '#applicant_validation_complete?' do
      before do
        applicant.update_attributes!({is_applying_coverage: true,
                                      is_required_to_file_taxes: false,
                                      is_claimed_as_tax_dependent: false,
                                      has_job_income: false,
                                      has_self_employment_income: false,
                                      has_other_income: false,
                                      has_deductions: false,
                                      has_enrolled_health_coverage: false,
                                      has_eligible_health_coverage: false,
                                      has_unemployment_income: false,
                                      is_pregnant: false,
                                      no_ssn: 0,
                                      ssn: '123456789',
                                      is_post_partum_period: false})
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_zero_income_amount_validation).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:no_ssn_reason_dropdown).and_return(false)
      end

      context 'has living_outside_state feature disabled' do
        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:living_outside_state).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
          applicant.update_attributes!({is_temporarily_out_of_state: nil})
        end

        it 'should validate applicant as complete' do
          expect(applicant.applicant_validation_complete?).to eq true
        end
      end

      context 'has_medicare_cubcare_eligible feature disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
          applicant.update_attributes!({
                                         has_eligible_medicaid_cubcare: nil,
                                         has_eligibility_changed: nil,
                                         has_household_income_changed: nil,
                                         person_coverage_end_on: nil
                                       })
        end

        it 'should validate applicant as complete' do
          expect(applicant.applicant_validation_complete?).to eq true
        end

        context 'has 0.00 income' do
          before do
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
            allow(applicant).to receive(:medicare_eligible_qns).and_return(true)
            allow(applicant).to receive(:valid?).and_return(true)
            applicant.update_attributes!({has_job_income: nil,
                                          has_self_employment_income: nil,
                                          has_other_income: nil,
                                          has_unemployment_income: nil})
            applicant.incomes << income
            applicant.incomes.first.update_attributes(amount: Money.new('0.00'))
          end

          it "validates $0 incomes" do
            expect(applicant.applicant_validation_complete?).to eq true
          end
        end

        context 'has negative income amount' do
          before do
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
            income
            applicant.incomes.first.update_attributes(amount: -100.00, kind: 'net_self_employment')
          end

          it 'should return true as amount is negative for income with kind net_self_employment' do
            expect(applicant.applicant_validation_complete?).to eq true
          end
        end

        context 'has nil income amount' do
          before do
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
            income
            applicant.incomes.first.update_attributes(amount: nil)
          end

          it 'should return false as income amount is nil' do
            expect(applicant.applicant_validation_complete?).to eq false
          end
        end
      end

      context 'has_medicare_cubcare_eligible feature enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(true)
        end

        context 'medicare_eligible_qns not answered' do
          before do
            applicant.update_attributes!({
                                           has_eligible_medicaid_cubcare: false,
                                           has_eligibility_changed: true,
                                           has_household_income_changed: nil,
                                           person_coverage_end_on: nil
                                         })
          end

          it 'should not validate applicant as complete' do
            expect(applicant.applicant_validation_complete?).to eq false
          end

          context 'person_coverage_end_on not given after selecting yes to has_eligibility_changed' do
            before do
              applicant.update_attributes!({
                                             has_eligible_medicaid_cubcare: false,
                                             has_eligibility_changed: true,
                                             has_household_income_changed: false,
                                             person_coverage_end_on: nil
                                           })
            end

            it 'should not validate applicant as complete' do
              expect(applicant.applicant_validation_complete?).to eq false
            end
          end
        end

        context 'medicare_eligible_qns answered' do
          before do
            applicant.update_attributes!({
                                           has_eligible_medicaid_cubcare: false,
                                           has_eligibility_changed: true,
                                           has_household_income_changed: true,
                                           person_coverage_end_on: Date.today
                                         })
          end

          it 'should validate applicant as complete' do
            expect(applicant.applicant_validation_complete?).to eq true
          end
        end
      end

      context 'applicant not applying for coverage and ssn is not present' do
        before do
          applicant.update_attributes!(ssn: nil, no_ssn: nil, is_applying_coverage: false)
        end

        it 'should return true as ssn is not mandatory for non applicant' do
          expect(applicant.applicant_validation_complete?).to eq true
        end
      end

      context 'applicant applying for coverage and ssn is not present' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
          applicant.update_attributes!(ssn: nil, no_ssn: '0', is_applying_coverage: true)
        end

        it 'should return false as ssn is mandatory for an applicant' do
          expect(applicant.applicant_validation_complete?).to eq false
        end
      end

      context 'applicant applying for coverage and ssn is not applied for while no ssn reason dropdown is enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:has_medicare_cubcare_eligible).and_return(false)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:no_ssn_reason_dropdown).and_return(true)
        end

        it 'should return false if non_ssn_apply_reason is not given' do
          applicant.update_attributes!(ssn: nil, no_ssn: '1', is_ssn_applied: false, is_applying_coverage: true)
          expect(applicant.applicant_validation_complete?).to eq false
        end

        it 'should return true if non_ssn_apply_reason is given' do
          applicant.update_attributes!(ssn: nil, no_ssn: '1', is_ssn_applied: false, is_applying_coverage: true, non_ssn_apply_reason: 'test reason')
          expect(applicant.applicant_validation_complete?).to eq true
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
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:no_ssn_reason_dropdown).and_return(false)
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

  context "#covering_applicant_exists" do
    before do
      applicant.update_attributes!({
                                     first_name: "Dusty",
                                     last_name: "Roberts",
                                     is_applying_coverage: true,
                                     is_required_to_file_taxes: false,
                                     is_claimed_as_tax_dependent: false,
                                     has_job_income: false,
                                     has_self_employment_income: false,
                                     has_other_income: false,
                                     has_deductions: false,
                                     has_enrolled_health_coverage: false,
                                     has_eligible_health_coverage: false,
                                     has_unemployment_income: false,
                                     is_pregnant: false,
                                     no_ssn: 0,
                                     ssn: '123456789',
                                     is_post_partum_period: false
                                   })
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:question_required).and_return(false)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:pregnancy_due_on_required).and_return(false)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_zero_income_amount_validation).and_return(true)
      allow(applicant).to receive(:claimed_as_tax_dependent_by).and_return("1")
    end

    it "should produce correct error message when tax claimer is not present" do
      applicant.covering_applicant_exists?
      expect(applicant.errors.full_messages).to include('Applicant claiming Dusty Roberts as tax dependent not present.')
    end
  end

  context 'propagate_applicant' do
    before do
      allow(FinancialAssistance::Operations::Families::CreateOrUpdateMember).to receive(:new).and_call_original
      applicant.assign_attributes({
                                    is_pregnant: true,
                                    children_expected_count: 1,
                                    pregnancy_due_on: nil,
                                    is_applying_coverage: true,
                                    is_physically_disabled: nil
                                  })
    end

    it 'should not propagate when callback_update is true' do
      applicant.callback_update = true
      applicant.save!
      expect(FinancialAssistance::Operations::Families::CreateOrUpdateMember).to_not have_received(:new)
    end

    context 'application is in draft' do
      before do
        application.reload
        application.applicants.first.save!
      end

      it 'should trigger operation call as application is in draft state' do
        expect(FinancialAssistance::Operations::Families::CreateOrUpdateMember).to have_received(:new)
      end
    end

    context 'application is not in draft' do
      before do
        application.update_attributes!(aasm_state: 'submitted')
        application.applicants.first.save!
      end

      it 'should not trigger operation call as application is in draft state' do
        expect(FinancialAssistance::Operations::Families::CreateOrUpdateMember).to_not have_received(:new)
      end
    end

    context "when primary address changes" do
      let!(:application2) do
        FactoryBot.create(:application,
                          family_id: application.family_id,
                          aasm_state: 'draft',
                          assistance_year: TimeKeeper.date_of_record.year,
                          effective_date: Date.today)
      end

      let!(:applicant1) do

        FactoryBot.create(:financial_assistance_applicant, :with_home_address,
                          application: application2,
                          dob: Date.today - 38.years,
                          is_primary_applicant: true,
                          same_with_primary: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context "when same_with_primary is true" do
        let!(:applicant2) do
          FactoryBot.create(:financial_assistance_applicant,
                            application: application2,
                            dob: Date.today - 38.years,
                            is_primary_applicant: false,
                            same_with_primary: true,
                            family_member_id: BSON::ObjectId.new)
        end

        let!(:relationship) do
          application2.ensure_relationship_with_primary(applicant2, 'spouse')
          application2.reload
        end

        it 'should update dependent address' do
          expect(application2.applicants[1].addresses.present?).to be_falsey
          application2.reload
          application2.applicants.first.addresses.first.assign_attributes(city: "was")
          application2.save!
          expect(application2.applicants[1].addresses.present?).to be_truthy
        end
      end

      context "when same_with_primary is false" do
        let!(:applicant2) do
          FactoryBot.create(:financial_assistance_applicant,
                            application: application2,
                            dob: Date.today - 38.years,
                            is_primary_applicant: false,
                            same_with_primary: false,
                            family_member_id: BSON::ObjectId.new)
        end

        let!(:relationship) do
          application2.ensure_relationship_with_primary(applicant2, 'spouse')
          application2.reload
        end

        it 'should not update dependent address' do
          expect(application2.applicants[1].addresses.present?).to be_falsey
          application2.reload
          application2.applicants.first.addresses.first.assign_attributes(city: "was")
          application2.save!
          expect(application2.applicants[1].addresses.present?).to be_falsey
        end
      end
    end
  end

  context 'propagate_destroy' do
    before do
      allow(::Operations::Families::DropFamilyMember).to receive(:new).and_call_original
      applicant.assign_attributes({
                                    is_pregnant: true,
                                    children_expected_count: 1,
                                    pregnancy_due_on: nil,
                                    is_applying_coverage: true,
                                    is_physically_disabled: nil
                                  })
    end

    it 'should not propagate when callback_update is true' do
      applicant.callback_update = true
      applicant.destroy!
      expect(::Operations::Families::DropFamilyMember).to_not have_received(:new)
    end

    context 'application is in draft' do
      before do
        application.reload
        applicant.destroy!
      end

      it 'should trigger operation call as application is in draft state' do
        expect(Operations::Families::DropFamilyMember).to have_received(:new)
      end
    end

    context 'application is not in draft' do
      before do
        application.update_attributes!(aasm_state: 'submitted')
        applicant.destroy!
      end

      it 'should not trigger operation call as application is in draft state' do
        expect(Operations::Families::DropFamilyMember).to_not have_received(:new)
      end
    end
  end

  describe '#valid_family_relationships' do
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 38.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    let!(:applicant3) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 38.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    context "spousal relationships" do

      context "invalid spousal relationships" do
        let!(:relationship_1) do
          application.ensure_relationship_with_primary(applicant2, 'spouse')
          applicant.save!
        end

        let!(:relationship_2) do
          application.add_or_update_relationships(applicant2, applicant3, 'siblings')
          applicant2.save!
        end

        let!(:relationship_3) do
          application.add_or_update_relationships(applicant3, applicant, 'domestic_partner')
          applicant3.save!
        end

        it "returns false" do
          expect(applicant.valid_spousal_relationship?).to eq false
        end
      end

      context "valid spousal relationships" do

        let!(:relationship_1) do
          application.ensure_relationship_with_primary(applicant2, 'spouse')
          application.reload
        end

        let!(:relationship_2) do
          application.add_or_update_relationships(applicant2, applicant3, 'parent')
          applicant2.save!
        end

        let!(:relationship_3) do
          application.add_or_update_relationships(applicant3, applicant, 'child')
          applicant3.save!
        end

        it "returns true" do
          expect(applicant.valid_spousal_relationship?).to eq true
        end
      end
    end

    context "child relationships" do

      context "invalid child relationships" do

        let!(:relationship_1) do
          application.ensure_relationship_with_primary(applicant2, 'domestic_partner')
          application.reload
        end

        let!(:relationship_2) do
          application.add_or_update_relationships(applicant2, applicant3, 'parent')
          applicant2.save!
        end

        let!(:relationship_3) do
          application.add_or_update_relationships(applicant3, applicant, 'unrelated')
          applicant3.save!
        end

        it "returns false" do
          expect(applicant3.valid_family_relationships?).to eql(false)
        end
      end

      context "valid child relationships" do

        let!(:relationship_1) do
          application.ensure_relationship_with_primary(applicant2, 'domestic_partner')
          application.reload
        end

        let!(:relationship_2) do
          application.add_or_update_relationships(applicant2, applicant3, 'parent')
          applicant2.save!
        end

        let!(:relationship_3) do
          application.add_or_update_relationships(applicant3, applicant, 'child_of_domestic_partner')
          applicant3.save!
        end

        it "returns true" do
          expect(applicant.valid_family_relationships?).to eql(true)
        end
      end
    end

    context "in-law relationships" do
      let!(:applicant4) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      let!(:applicant5) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context "invalid in-law relationships" do
        let(:set_up_relationships) do
          application.ensure_relationship_with_primary(applicant2, 'child')
          application.ensure_relationship_with_primary(applicant3, 'spouse')
          application.ensure_relationship_with_primary(applicant4, 'sibling')
          application.ensure_relationship_with_primary(applicant5, 'unrelated')
          application.add_or_update_relationships(applicant2, applicant3, 'child')
          application.add_or_update_relationships(applicant2, applicant4, 'nephew_or_niece')
          application.add_or_update_relationships(applicant2, applicant5, 'nephew_or_niece')
          application.add_or_update_relationships(applicant3, applicant4, 'brother_or_sister_in_law')
          application.add_or_update_relationships(applicant3, applicant5, 'unrelated')
          application.add_or_update_relationships(applicant4, applicant5, 'spouse')

          application.build_relationship_matrix
          application.save(validate: false)
        end

        before do
          set_up_relationships
        end

        it "returns false" do
          expect(applicant5.valid_family_relationships?).to eql(false)
        end
      end

      context "valid in-law relationships" do
        let(:set_up_relationships) do
          application.ensure_relationship_with_primary(applicant2, 'child')
          application.ensure_relationship_with_primary(applicant3, 'spouse')
          application.ensure_relationship_with_primary(applicant4, 'sibling')
          application.ensure_relationship_with_primary(applicant5, 'brother_or_sister_in_law')
          application.add_or_update_relationships(applicant2, applicant3, 'child')
          application.add_or_update_relationships(applicant2, applicant4, 'nephew_or_niece')
          application.add_or_update_relationships(applicant2, applicant5, 'nephew_or_niece')
          application.add_or_update_relationships(applicant3, applicant4, 'brother_or_sister_in_law')
          application.add_or_update_relationships(applicant3, applicant5, 'brother_or_sister_in_law')
          application.add_or_update_relationships(applicant4, applicant5, 'spouse')

          application.build_relationship_matrix
          application.save(validate: false)
        end

        before do
          set_up_relationships
        end

        it "returns true" do
          expect(applicant5.valid_family_relationships?).to eql(true)
        end
      end
    end

    describe "sibling relationships" do

      let!(:applicant4) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      let!(:applicant5) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context "valid sibling relationships" do
        let(:set_up_relationships) do
          application.ensure_relationship_with_primary(applicant2, 'spouse')
          application.ensure_relationship_with_primary(applicant3, 'child')
          application.ensure_relationship_with_primary(applicant4, 'child')
          application.ensure_relationship_with_primary(applicant5, 'child')
          application.add_or_update_relationships(applicant2, applicant3, 'child')
          application.add_or_update_relationships(applicant2, applicant4, 'child')
          application.add_or_update_relationships(applicant2, applicant5, 'child')
          application.add_or_update_relationships(applicant3, applicant4, 'sibling')
          application.add_or_update_relationships(applicant3, applicant5, 'sibling')
          application.add_or_update_relationships(applicant4, applicant5, 'sibling')

          application.build_relationship_matrix
          application.save(validate: false)
        end

        before do
          set_up_relationships
        end

        it "returns true" do
          application.applicants.each do |applicant|
            expect(applicant.valid_family_relationships?).to eql(true)
          end
        end
      end

      context "invalid sibling relationships" do
        let(:set_up_relationships) do
          application.ensure_relationship_with_primary(applicant2, 'spouse')
          application.ensure_relationship_with_primary(applicant3, 'child')
          application.ensure_relationship_with_primary(applicant4, 'child')
          application.ensure_relationship_with_primary(applicant5, 'child')
          application.add_or_update_relationships(applicant2, applicant3, 'child')
          application.add_or_update_relationships(applicant2, applicant4, 'child')
          application.add_or_update_relationships(applicant2, applicant5, 'child')
          application.add_or_update_relationships(applicant3, applicant4, 'sibling')
          application.add_or_update_relationships(applicant3, applicant5, 'sibling')
          application.add_or_update_relationships(applicant4, applicant5, 'parent')

          application.build_relationship_matrix
          application.save(validate: false)
        end

        before do
          set_up_relationships
        end

        it "returns false" do
          expect(applicant4.valid_family_relationships?).to eql(false)
        end
      end
    end
  end

  describe '#is_spouse_of_primary' do
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 38.years,
                        is_primary_applicant: false,
                        family_member_id: BSON::ObjectId.new)
    end

    context 'applicant2 is spouse to primary_applicant' do
      let!(:relationship) do
        application.ensure_relationship_with_primary(applicant2, 'spouse')
        application.reload
      end

      it 'should return true' do
        expect(applicant2.is_spouse_of_primary).to eq(true)
      end
    end

    context 'when applicant2 is spouse to primary_applicant and not applicant3' do
      let!(:applicant3) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      let!(:relationship) do
        application.ensure_relationship_with_primary(applicant2, 'spouse')
        application.reload
      end

      it 'should return false as there is no spouse relationship b/w applicant3 & primary_applicant' do
        expect(applicant3.is_spouse_of_primary).to eq(false)
      end
    end

    context 'applicant2 is spouse to non primary_applicant(applicant3)' do
      let!(:applicant3) do
        FactoryBot.create(:applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      let!(:relationship) do
        application.add_or_update_relationships(applicant2, applicant3, 'spouse')
        application.reload
      end

      it 'should return false' do
        expect(applicant2.is_spouse_of_primary).to eq(false)
      end
    end


    context 'when is_spouse_of_primary id called for primary_applicant' do
      it 'should return false' do
        expect(application.primary_applicant.is_spouse_of_primary).to eq(false)
      end
    end

    context "create_evidences" do
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:esi_mec_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:mec_check).and_return(true)
      end

      it "should create esi, non_esi and mec_check evidences and keep them in pending state" do
        applicant.create_evidences
        applicant.reload
        expect(applicant.esi_evidence).to be_present
        expect(applicant.esi_evidence.aasm_state).to eq 'pending'
        expect(applicant.non_esi_evidence).to be_present
        expect(applicant.non_esi_evidence.aasm_state).to eq 'pending'
        expect(applicant.local_mec_evidence).to be_present
        expect(applicant.local_mec_evidence.aasm_state).to eq 'pending'
      end

      it 'should not create/override if given evidence is already present' do
        esi_evidence = applicant.create_esi_evidence(key: :esi, title: "ESI MEC", aasm_state: 'verified')
        applicant.create_evidences
        expect(applicant.reload.esi_evidence.id).to eq esi_evidence.id
        expect(applicant.esi_evidence.aasm_state).not_to eq 'pending'
        expect(applicant.esi_evidence.aasm_state).to eq 'verified'
        expect(applicant.non_esi_evidence).to be_present
        expect(applicant.non_esi_evidence.aasm_state).to eq 'pending'
      end
    end

    context 'set evidence to verified' do
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context 'for income evidence' do

        before do
          applicant.create_income_evidence(key: :income, title: "Income", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
        end

        let(:current_evidence) { applicant.income_evidence }

        it 'should set evidence verified' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_verified(current_evidence)
          current_evidence.reload
          expect(current_evidence.verified?).to be_truthy
        end

        it 'should set due_on, is_satisfied' do
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
          expect(current_evidence.due_on).to be_present
          applicant.set_evidence_verified(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          expect(current_evidence.due_on).to be_blank
        end
      end

      context 'for esi mec evidence' do

        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
        end

        let(:current_evidence) { applicant.esi_evidence }

        it 'should set evidence verified' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_verified(current_evidence)
          current_evidence.reload
          expect(current_evidence.verified?).to be_truthy
        end

        it 'should set due_on, is_satisfied' do
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
          expect(current_evidence.due_on).to be_present
          applicant.set_evidence_verified(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          expect(current_evidence.due_on).to be_blank
        end
      end
    end

    context 'set evidence to attested' do
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context 'for non esi evidence' do
        let(:current_evidence) { applicant.non_esi_evidence }

        before do
          applicant.create_non_esi_evidence(key: :income, title: "Non Esi", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
        end

        it 'should set evidence attested' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_attested(current_evidence)
          current_evidence.reload
          expect(current_evidence.attested?).to be_truthy
        end

        it 'should set due_on, is_satisfied' do
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
          expect(current_evidence.due_on).to be_present
          applicant.set_evidence_attested(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          expect(current_evidence.due_on).to be_blank
        end
      end

      context 'for esi mec evidence' do
        let(:current_evidence) { applicant.esi_evidence }

        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
        end

        it 'should set evidence attested' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_attested(current_evidence)
          current_evidence.reload
          expect(current_evidence.attested?).to be_truthy
        end

        it 'should set due_on, is_satisfied' do
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
          expect(current_evidence.due_on).to be_present
          applicant.set_evidence_attested(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          expect(current_evidence.due_on).to be_blank
        end
      end

      context "if evidence is verified" do
        let(:current_evidence) { applicant.esi_evidence }

        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'verified', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
        end

        it 'should set due_on, is_satisfied and leave evidence in verified state' do
          expect(current_evidence.verified?).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
          expect(current_evidence.due_on).to be_present
          applicant.set_evidence_attested(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          expect(current_evidence.attested?).to be_falsy
          expect(current_evidence.verified?).to be_truthy
        end
      end
    end

    context 'set evidence to outstanding' do
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context 'for income evidence' do
        before do
          applicant.create_income_evidence(key: :income, title: "Income", aasm_state: 'pending', verification_outstanding: false, is_satisfied: true)
        end

        let(:current_evidence) { applicant.income_evidence }

        it 'should move evidence to outstanding and set due date' do
          expect(current_evidence.pending?).to be_truthy
          expect(current_evidence.due_on).to eq nil
          applicant.set_evidence_outstanding(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.due_on).not_to eq nil
        end

        it 'should set is_satisfied and verification_outstanding' do
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          applicant.set_evidence_outstanding(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
        end
      end

      context 'for esi mec evidence' do

        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'pending', verification_outstanding: false, is_satisfied: true)
        end

        let(:current_evidence) { applicant.esi_evidence }

        it 'should set evidence verified' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_outstanding(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_truthy
        end

        it 'should set is_satisfied and verification_outstanding' do
          expect(current_evidence.verification_outstanding).to be_falsey
          expect(current_evidence.is_satisfied).to be_truthy
          applicant.set_evidence_outstanding(current_evidence)
          current_evidence.reload
          expect(current_evidence.verification_outstanding).to be_truthy
          expect(current_evidence.is_satisfied).to be_falsey
        end
      end
    end

    context 'set evidence to negative_response_received' do
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: BSON::ObjectId.new)
      end

      context 'for income evidence' do
        before do
          applicant.create_income_evidence(key: :income, title: "Income", aasm_state: 'pending', verification_outstanding: false, is_satisfied: true)
        end

        let(:current_evidence) { applicant.income_evidence }

        it 'should set evidence negative_response_received' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_to_negative_response(current_evidence)
          expect(current_evidence.reload.aasm_state).to eq 'negative_response_received'
        end
      end

      context 'for outstanding income evidence with due on' do
        before do
          applicant.create_income_evidence(key: :income, title: "Income", aasm_state: 'outstanding', verification_outstanding: true, is_satisfied: false, due_on: Date.today + 2.months)
        end

        let(:current_evidence) { applicant.income_evidence }

        it 'should transition evidence tonegative_response_received and due on to nil' do
          expect(current_evidence.outstanding?).to be_truthy
          expect(current_evidence.due_on.present?).to be_truthy
          applicant.set_evidence_to_negative_response(current_evidence)
          expect(current_evidence.reload.negative_response_received?).to be_truthy
          expect(current_evidence.due_on.present?).to be_falsey
        end
      end

      context 'for outstanding esi evidence with due on' do
        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'outstanding', verification_outstanding: true, is_satisfied: false, due_on: Date.today + 2.months)
        end

        let(:current_evidence) { applicant.esi_evidence }

        it 'should transition evidence to negative_response_received and due on to nil' do
          expect(current_evidence.outstanding?).to be_truthy
          expect(current_evidence.due_on.present?).to be_truthy
          applicant.set_evidence_to_negative_response(current_evidence)
          expect(current_evidence.reload.negative_response_received?).to be_truthy
          expect(current_evidence.due_on.present?).to be_falsey
        end
      end

      context 'for esi mec evidence' do
        before do
          applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'pending', verification_outstanding: false, is_satisfied: true)
        end

        let(:current_evidence) { applicant.esi_evidence }

        it 'should set evidence negative_response_received' do
          expect(current_evidence.pending?).to be_truthy
          applicant.set_evidence_to_negative_response(current_evidence)
          expect(current_evidence.reload.aasm_state).to eq 'negative_response_received'
        end
      end
    end
  end

  describe 'enrolled_with' do
    context 'a product with csr_variant_id of 01' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role)}
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let(:product) {double(id: '123', csr_variant_id: '01')}

      let!(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_enrollment_members,
          :individual_assisted,
          family: family,
          applied_aptc_amount: Money.new(44_500),
          consumer_role_id: person.consumer_role.id,
          enrollment_members: family.family_members
        )
      end

      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          application: application,
                          dob: Date.today - 38.years,
                          is_primary_applicant: false,
                          family_member_id: family.family_members.first.id)
      end

      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:mec_check).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:esi_mec_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
        allow(enrollment).to receive(:product).and_return(product)
        applicant.create_evidences
        applicant.create_eligibility_income_evidence
        applicant.income_evidence.move_to_pending!
      end

      context "when aptc is applied on enrolment member" do
        before do
          enrollment.hbx_enrollment_members.each {|hem| hem.applied_aptc_amount = 150 }
          enrollment.save!
        end

        context "when evidence is in pending state" do
          it "move to outstanding state" do
            applicant.enrolled_with(enrollment)
            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              expect(evidence.outstanding?).to eq true
              expect(evidence.due_on).to eq applicant.schedule_verification_due_on
            end
          end
        end

        context "when evidence is in negative_response_received state" do
          it "move to outstanding state" do
            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              evidence.negative_response_received!
            end

            applicant.enrolled_with(enrollment)

            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              expect(evidence.outstanding?).to eq true
              expect(evidence.due_on).to eq applicant.schedule_verification_due_on
            end
          end
        end
      end

      # Added to test changes of which csr codes can determine the aasm_state of an evidence
      # Recently (08/30/2023) a bug was discovered in which csr code '03' should have been changed to 'csr_02'
      context 'enrolled with a product with a specific csr code' do
        # income evidence is only being used as an example here -- this can be applied to
        let(:product_csr_02) {double(id: '124', csr_variant_id: '02')}
        let(:product_csr_03) {double(id: '125', csr_variant_id: '03')}
        let(:evidence) { applicant.income_evidence }

        before do
          # need to set aptc amount to 0 to ensure only csr codes being evaluated against
          enrollment.update(applied_aptc_amount: 0)
        end

        context 'with a csr_variant_id of 02' do
          before do
            allow(enrollment).to receive(:product).and_return(product_csr_02)
          end

          it 'moves evidence to an outstanding state' do
            applicant.enrolled_with(enrollment)
            expect(evidence.aasm_state).to eq('outstanding')
          end
        end

        context 'with a csr_variant_id of 03' do
          before do
            allow(enrollment).to receive(:product).and_return(product_csr_03)
          end

          it 'moves evidence to a negative_response_received state' do
            applicant.enrolled_with(enrollment)
            expect(evidence.aasm_state).to eq('negative_response_received')
          end
        end
      end

      context "when aptc & csr are not applied on enrollment member" do
        context "when evidence is in pending state" do
          it "move to outstanding" do
            applicant.enrolled_with(enrollment)
            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              expect(evidence.outstanding?).to eq true
              expect(evidence.negative_response_received?).to eq false
              expect(evidence.due_on).to eq applicant.schedule_verification_due_on
            end
          end
        end

        context "when evidence is in negative_response_received state" do
          it "will move to outstanding" do
            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              evidence.negative_response_received!
            end

            applicant.enrolled_with(enrollment)

            FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
              evidence = applicant.send(evidence_type)
              expect(evidence.outstanding?).to eq true
              expect(evidence.negative_response_received?).to eq false
              expect(evidence.due_on).to eq applicant.schedule_verification_due_on
            end
          end
        end
      end
    end
  end

  describe '#embedded_document_section_entry_complete?' do
    context 'other_income' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:unemployment_income).and_return(false)
      end

      context 'where feature american_indian_alaskan_native_income is enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:american_indian_alaskan_native_income).and_return(true)
        end

        context 'where applicant is indian_tribe_member' do
          before do
            applicant.update_attributes!(indian_tribe_member: true, has_american_indian_alaskan_native_income: nil)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return false as other_income section is not complete' do
            expect(@result).to be_falsey
          end
        end

        context 'where applicant is not indian_tribe_member' do
          before do
            applicant.update_attributes!(indian_tribe_member: false, has_other_income: false)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return true as other_income section is complete' do
            expect(@result).to be_truthy
          end
        end
      end

      context 'where feature american_indian_alaskan_native_income is disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:american_indian_alaskan_native_income).and_return(false)
        end

        context 'where applicant is indian_tribe_member' do
          before do
            applicant.update_attributes!(indian_tribe_member: true, has_american_indian_alaskan_native_income: nil, has_other_income: false)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return true as other_income section is complete' do
            expect(@result).to be_truthy
          end
        end

        context 'where applicant is not indian_tribe_member' do
          before do
            applicant.update_attributes!(indian_tribe_member: false, has_other_income: false)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return true as other_income section is complete' do
            expect(@result).to be_truthy
          end
        end
      end

      # ssi_income_types
      context 'when feature ssi_income_types is enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ssi_income_types).and_return(true)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:american_indian_alaskan_native_income).and_return(false)
        end

        context 'when applicant has other_income with incompleted social security benefit' do
          before do
            applicant.update_attributes!(has_other_income: true)
            inc = ::FinancialAssistance::Income.new({
                                                      kind: 'social_security_benefit',
                                                      frequency_kind: 'yearly',
                                                      amount: 30_000.00,
                                                      start_on: TimeKeeper.date_of_record.beginning_of_month
                                                    })
            applicant.incomes = [inc]
            applicant.save!
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return false' do
            expect(@result).to be_falsey
          end
        end

        context 'when applicant has_other_income without other incomes' do
          before do
            applicant.update_attributes!(has_other_income: true)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return false' do
            expect(@result).to be_falsey
          end
        end

        context 'where applicant has_other_income with completed social security benefit' do
          before do
            applicant.update_attributes!(has_other_income: true)
            inc = ::FinancialAssistance::Income.new({
                                                      kind: 'social_security_benefit',
                                                      frequency_kind: 'yearly',
                                                      amount: 30_000.00,
                                                      start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                      ssi_type: 'retirement'
                                                    })
            applicant.incomes = [inc]
            applicant.save!
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return true' do
            expect(@result).to be_truthy
          end
        end
      end

      context 'when feature ssi_income_types is disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ssi_income_types).and_return(false)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:american_indian_alaskan_native_income).and_return(false)
        end

        context 'when applicant has other_income with incompleted social security benefit' do
          before do
            applicant.update_attributes!(has_other_income: true)
            inc = ::FinancialAssistance::Income.new({
                                                      kind: 'social_security_benefit',
                                                      frequency_kind: 'yearly',
                                                      amount: 30_000.00,
                                                      start_on: TimeKeeper.date_of_record.beginning_of_month
                                                    })
            applicant.incomes = [inc]
            applicant.save!
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return false' do
            expect(@result).to be_truthy
          end
        end

        context 'when applicant has_other_income without other incomes' do
          before do
            applicant.update_attributes!(has_other_income: true)
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return false' do
            expect(@result).to be_falsey
          end
        end

        context 'where applicant has_other_income with completed social security benefit' do
          before do
            applicant.update_attributes!(has_other_income: true)
            inc = ::FinancialAssistance::Income.new({
                                                      kind: 'social_security_benefit',
                                                      frequency_kind: 'yearly',
                                                      amount: 30_000.00,
                                                      start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                      ssi_type: 'retirement'
                                                    })
            applicant.incomes = [inc]
            applicant.save!
            @result = applicant.embedded_document_section_entry_complete?(:other_income)
          end

          it 'should return true' do
            expect(@result).to be_truthy
          end
        end
      end
    end
  end

  describe '#has_valid_address?' do
    let(:applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        :with_home_address,
        application: application,
        dob: Date.today - 40.years,
        is_primary_applicant: true,
        family_member_id: BSON::ObjectId.new
      )
    end
    let(:mailing_address) { FactoryBot.build(:financial_assistance_address, :mailing_address)}
    let(:work_address) { FactoryBot.build(:financial_assistance_address, :work_address)}

    context 'invalid addresses' do
      it 'should consider no address at all invalid' do
        applicant.addresses = []
        applicant.save
        expect(applicant.has_valid_address?).to eq false
      end

      it 'should consider work address invalid' do
        applicant.addresses = [work_address]
        applicant.save
        expect(applicant.has_valid_address?).to eq false
      end
    end

    context 'out_of_state_primary feature enabled' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:out_of_state_primary).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
      end

      context 'valid addresses' do
        context 'applicant lives in-state' do
          it 'should consider in-state home address valid' do
            expect(applicant.has_valid_address?).to eq true
          end

          it 'should consider in-state mailing address valid' do
            applicant.addresses = [mailing_address]
            applicant.save
            expect(applicant.has_valid_address?).to eq true
          end
        end

        context 'applicant lives out-of-state' do
          it 'should consider out-of-state home address valid' do
            applicant.addresses.first.state = "OS"
            applicant.save
            expect(applicant.has_valid_address?).to eq true
          end

          it 'should consider out-of-state mailing address valid' do
            applicant.addresses = [mailing_address]
            applicant.addresses.first.state = "OS"
            applicant.save
            expect(applicant.has_valid_address?).to eq true
          end
        end
      end
    end

    context 'out_of_state_primary feature disabled' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:out_of_state_primary).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
      end

      context 'valid addresses' do
        it 'should consider in-state home address valid' do
          expect(applicant.has_valid_address?).to eq true
        end

        it 'should consider in-state mailing address valid' do
          applicant.addresses = [mailing_address]
          applicant.save
          expect(applicant.has_valid_address?).to eq true
        end
      end

      context 'invalid addresses' do
        it 'should consider out-of-state address invalid' do
          applicant.addresses.first.state = "OS"
          applicant.save
          expect(applicant.has_valid_address?).to eq false
        end
      end
    end
  end

  describe 'clone_evidences' do
    let!(:application2) do
      FactoryBot.create(:application,
                        family_id: application.family_id,
                        aasm_state: 'draft',
                        assistance_year: TimeKeeper.date_of_record.year,
                        effective_date: Date.today)
    end

    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        application: application2,
                        dob: Date.today - 40.years,
                        is_primary_applicant: true,
                        family_member_id: applicant.family_member_id)
    end

    let!(:income_evidence) do
      applicant.create_income_evidence(key: :income,
                                       title: 'Income',
                                       aasm_state: 'pending',
                                       due_on: Date.today,
                                       verification_outstanding: true,
                                       is_satisfied: false)
    end

    let!(:esi_evidence) do
      applicant.create_esi_evidence(key: :esi_mec, title: "Esi", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
    end

    let!(:non_esi_evidence) do
      applicant.create_non_esi_evidence(key: :non_esi_mec, title: "Non Esi", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
    end

    let!(:local_mec_evidence) do
      applicant.create_local_mec_evidence(key: :local_mec, title: "Local Mec", aasm_state: 'pending', due_on: Date.today, verification_outstanding: true, is_satisfied: false)
    end

    before do
      create_embedded_docs_for_evidences(applicant)
      applicant.clone_evidences(applicant2)
      applicant2.save!
    end

    context 'income_evidence' do
      before do
        @new_income_evi = applicant2.income_evidence
        @new_verification_history = @new_income_evi.verification_histories.first
        @new_request_result = @new_income_evi.request_results.first
        @new_wfst = @new_income_evi.workflow_state_transitions.first
        @new_document = @new_income_evi.documents.first
      end

      it 'should clone income_evidence' do
        expect(@new_income_evi).not_to be_nil
        expect(@new_income_evi.created_at).not_to be_nil
        expect(@new_income_evi.updated_at).not_to be_nil
      end

      it 'should clone verification_history' do
        expect(@new_income_evi.verification_histories).not_to be_empty
        expect(@new_verification_history.created_at).not_to be_nil
        expect(@new_verification_history.updated_at).not_to be_nil
      end

      it 'should clone request_result' do
        expect(@new_income_evi.request_results).not_to be_empty
        expect(@new_request_result.created_at).not_to be_nil
        expect(@new_request_result.updated_at).not_to be_nil
      end

      it 'should clone workflow_state_transition' do
        expect(@new_income_evi.workflow_state_transitions).not_to be_empty
        expect(@new_wfst.created_at).not_to be_nil
        expect(@new_wfst.updated_at).not_to be_nil
      end

      it 'should clone documents' do
        expect(@new_income_evi.documents).not_to be_empty
        expect(@new_document.created_at).not_to be_nil
        expect(@new_document.updated_at).not_to be_nil
      end
    end

    context 'esi_evidence' do
      before do
        @new_esi_evi = applicant2.esi_evidence
        @new_verification_history = @new_esi_evi.verification_histories.first
        @new_request_result = @new_esi_evi.request_results.first
        @new_wfst = @new_esi_evi.workflow_state_transitions.first
        @new_document = @new_esi_evi.documents.first
      end

      it 'should clone esi_evidence' do
        expect(@new_esi_evi).not_to be_nil
        expect(@new_esi_evi.created_at).not_to be_nil
        expect(@new_esi_evi.updated_at).not_to be_nil
      end

      it 'should clone verification_history' do
        expect(@new_esi_evi.verification_histories).not_to be_empty
        expect(@new_verification_history.created_at).not_to be_nil
        expect(@new_verification_history.updated_at).not_to be_nil
      end

      it 'should clone request_result' do
        expect(@new_esi_evi.request_results).not_to be_empty
        expect(@new_request_result.created_at).not_to be_nil
        expect(@new_request_result.updated_at).not_to be_nil
      end

      it 'should clone workflow_state_transition' do
        expect(@new_esi_evi.workflow_state_transitions).not_to be_empty
        expect(@new_wfst.created_at).not_to be_nil
        expect(@new_wfst.updated_at).not_to be_nil
      end

      it 'should clone documents' do
        expect(@new_esi_evi.documents).not_to be_empty
        expect(@new_document.created_at).not_to be_nil
        expect(@new_document.updated_at).not_to be_nil
      end
    end

    context 'non_esi_evidence' do
      before do
        @new_non_esi_evi = applicant2.non_esi_evidence
        @new_verification_history = @new_non_esi_evi.verification_histories.first
        @new_request_result = @new_non_esi_evi.request_results.first
        @new_wfst = @new_non_esi_evi.workflow_state_transitions.first
        @new_document = @new_non_esi_evi.documents.first
      end

      it 'should clone non_esi_evidence' do
        expect(@new_non_esi_evi).not_to be_nil
        expect(@new_non_esi_evi.created_at).not_to be_nil
        expect(@new_non_esi_evi.updated_at).not_to be_nil
      end

      it 'should clone verification_history' do
        expect(@new_non_esi_evi.verification_histories).not_to be_empty
        expect(@new_verification_history.created_at).not_to be_nil
        expect(@new_verification_history.updated_at).not_to be_nil
      end

      it 'should clone request_result' do
        expect(@new_non_esi_evi.request_results).not_to be_empty
        expect(@new_request_result.created_at).not_to be_nil
        expect(@new_request_result.updated_at).not_to be_nil
      end

      it 'should clone workflow_state_transition' do
        expect(@new_non_esi_evi.workflow_state_transitions).not_to be_empty
        expect(@new_wfst.created_at).not_to be_nil
        expect(@new_wfst.updated_at).not_to be_nil
      end

      it 'should clone documents' do
        expect(@new_non_esi_evi.documents).not_to be_empty
        expect(@new_document.created_at).not_to be_nil
        expect(@new_document.updated_at).not_to be_nil
      end
    end

    context 'local_mec_evidence' do
      before do
        @new_local_mec_evi = applicant2.local_mec_evidence
        @new_verification_history = @new_local_mec_evi.verification_histories.first
        @new_request_result = @new_local_mec_evi.request_results.first
        @new_wfst = @new_local_mec_evi.workflow_state_transitions.first
        @new_document = @new_local_mec_evi.documents.first
      end

      it 'should clone local_mec_evidence' do
        expect(@new_local_mec_evi).not_to be_nil
        expect(@new_local_mec_evi.created_at).not_to be_nil
        expect(@new_local_mec_evi.updated_at).not_to be_nil
      end

      it 'should clone verification_history' do
        expect(@new_local_mec_evi.verification_histories).not_to be_empty
        expect(@new_verification_history.created_at).not_to be_nil
        expect(@new_verification_history.updated_at).not_to be_nil
      end

      it 'should clone request_result' do
        expect(@new_local_mec_evi.request_results).not_to be_empty
        expect(@new_request_result.created_at).not_to be_nil
        expect(@new_request_result.updated_at).not_to be_nil
      end

      it 'should clone workflow_state_transition' do
        expect(@new_local_mec_evi.workflow_state_transitions).not_to be_empty
        expect(@new_wfst.created_at).not_to be_nil
        expect(@new_wfst.updated_at).not_to be_nil
      end

      it 'should clone documents' do
        expect(@new_local_mec_evi.documents).not_to be_empty
        expect(@new_document.created_at).not_to be_nil
        expect(@new_document.updated_at).not_to be_nil
      end
    end
  end

  describe '#attributes_for_export' do
    let(:test_applicant) do
      applicant.five_year_bar_applies = five_year_bar
      applicant.five_year_bar_met = five_year_bar
      applicant.qualified_non_citizen = qualified_non_citizen
      applicant.save!
      applicant
    end

    before { @result = test_applicant.attributes_for_export }

    context 'for five_year_bar is set to true' do
      let(:five_year_bar) { true }
      let(:qualified_non_citizen) { true }

      it 'should include the keys and assign correct values' do
        expect(@result[:five_year_bar_applies]).to eq(true)
        expect(@result[:five_year_bar_met]).to eq(true)
        expect(@result[:qualified_non_citizen]).to eq(true)
      end
    end

    context 'for five_year_bar and qualified_non_citizen set to false' do
      let(:five_year_bar) { false }
      let(:qualified_non_citizen) { false }

      it 'should include the keys and assign correct values' do
        expect(@result[:five_year_bar_applies]).to eq(false)
        expect(@result[:five_year_bar_met]).to eq(false)
        expect(@result[:qualified_non_citizen]).to eq(false)
      end
    end

    context 'for five_year_bar and qualified_non_citizen set to nil' do
      let(:five_year_bar) { nil }
      let(:qualified_non_citizen) { nil }

      it 'should include the keys and assign correct values' do
        expect(@result[:five_year_bar_applies]).to eq(nil)
        expect(@result[:five_year_bar_met]).to eq(nil)
        expect(@result[:qualified_non_citizen]).to eq(nil)
      end
    end
  end

  def create_embedded_docs_for_evidences(appli)
    [appli.income_evidence, appli.esi_evidence, appli.non_esi_evidence, appli.local_mec_evidence].each do |evidence|
      create_verification_history(evidence)
      create_request_result(evidence)
      create_workflow_state_transition(evidence)
      create_document(evidence)
    end
  end

  def create_verification_history(evidence)
    evidence.verification_histories.create(action: 'verify', update_reason: 'Document in EnrollApp', updated_by: 'admin@user.com')
  end

  def create_request_result(evidence)
    evidence.request_results.create(result: 'verified', source: 'FDSH IFSV', raw_payload: 'raw_payload')
  end

  def create_workflow_state_transition(evidence)
    evidence.workflow_state_transitions.create(to_state: "approved", transition_at: TimeKeeper.date_of_record, reason: "met minimum criteria",
                                               comment: "consumer provided proper documentation", user_id: BSON::ObjectId.from_time(DateTime.now))
  end

  def create_document(evidence)
    evidence.documents.create(title: 'document.pdf', creator: 'mehl', subject: 'document.pdf', publisher: 'mehl', type: 'text', identifier: 'identifier',
                              source: 'enroll_system', language: 'en')
  end

  context 'adding member_determinations' do
    let(:override_rules) {::AcaEntities::MagiMedicaid::Types::EligibilityOverrideRule.values}
    let(:member_determinations) do
      [medicaid_and_chip_member_determination]
    end

    let(:medicaid_and_chip_member_determination) do
      {
        kind: 'Medicaid/CHIP Determination',
        criteria_met: false,
        determination_reasons: [],
        eligibility_overrides: medicaid_chip_eligibility_overrides
      }
    end

    let(:medicaid_chip_eligibility_overrides) do
      override_rules.map do |rule|
        {
          override_rule: rule,
          override_applied: false
        }
      end
    end

    before do
      @applicant = application.applicants.first
      @applicant.update(member_determinations: member_determinations)

    end

    it 'should successfully add all member determination attributes' do
      expect(@applicant.member_determinations.first.kind).to eq('Medicaid/CHIP Determination')
      expect(@applicant.member_determinations.first.criteria_met).to eq(false)
      expect(@applicant.member_determinations.first.determination_reasons).to eq([])
      expect(@applicant.member_determinations.first.eligibility_overrides.present?).to be_truthy
    end

    context 'eligibility_overrides' do
      it 'should successfully add all eligibility_overrides attributes' do
        override_rules.each do |rule|
          override = @applicant.member_determinations.first.eligibility_overrides.detect{|o| o.override_rule == rule}
          expect(override.present?).to be_truthy
          expect(override.override_applied).to eq(false)
          expect(override.created_at.present?).to be_truthy
          expect(override.updated_at.present?).to be_truthy
        end
      end
    end
  end
end