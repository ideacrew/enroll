# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::CalculateMonthlyAggregate do

  before do
    @eligible_months_setting = EnrollRegistry[:calculate_monthly_aggregate].settings(:eligible_months)
    allow(@eligible_months_setting).to receive(:item).and_return(false)
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 8, 1))
  end

  context 'for invalid params' do
    it 'should return a failure with a message' do
      expect(subject.call({family: 'family'}).failure).to eq('Given object is not a valid family object.')
    end
  end

  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:primary_fm) {family.primary_applicant}
  let!(:household) {family.active_household}
  let!(:current_date){TimeKeeper.date_of_record}
  let!(:year_start_date) {TimeKeeper.date_of_record.beginning_of_year}
  let(:current_year) { TimeKeeper.date_of_record.year }

  context 'for current year effective dates' do
    let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: year_start_date, effective_ending_on: nil)}
    let!(:ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_terminated',
                              changing: false,
                              effective_on: year_start_date,
                              terminated_on: terminated_on,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    context 'for full month enrollments' do
      let(:effective_on) {current_date}
      let(:terminated_on) {effective_on.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(780.00)
      end
    end

    context 'for effective date starting middle of month and existing enrrollment terminated in middle of the month' do
      let(:effective_on) {current_date + 14.days}
      let(:terminated_on) {effective_on.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(827.65)
      end
    end

    context 'for effective date starting middle of month and existing enrrollment terminated at the end of prev month' do
      let(:effective_on) {current_date + 14.days}
      let(:terminated_on) {current_date.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(857.44)
      end
    end

    context 'for effective date starting stat of month and existing enrrollment terminated in middle of the month' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date - 12.days}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(801.29)
      end
    end

    context 'for multiple enrollments with different subscribers' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date.prev_day}
      let!(:fm2) do
        per2 = FactoryBot.create(:person, :with_consumer_role)
        person.ensure_relationship_with(per2, 'spouse')
        FactoryBot.create(:family_member, family: family, person: per2)
      end
      let!(:hbx_enrollment2) do
        enr2 = FactoryBot.create(:hbx_enrollment,
                                 family: family,
                                 household: household,
                                 is_active: true,
                                 aasm_state: 'coverage_selected',
                                 changing: false,
                                 effective_on: year_start_date,
                                 terminated_on: nil,
                                 applied_aptc_amount: 100.00)
        FactoryBot.create(:hbx_enrollment_member, applicant_id: fm2.id, hbx_enrollment: enr2)
        enr2
      end

      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(540.00)
      end
    end

    context 'for multiple enrollments with same subscriber' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date.prev_month.prev_month.prev_day}
      let!(:hbx_enrollment2) do
        enr2 = FactoryBot.create(:hbx_enrollment,
                                 family: family,
                                 household: household,
                                 is_active: true,
                                 aasm_state: 'coverage_selected',
                                 changing: false,
                                 effective_on: terminated_on.next_day,
                                 terminated_on: nil,
                                 applied_aptc_amount: 100.00)
        FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr2)
        enr2
      end

      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(860.00)
      end

      context 'When one of the enrollment as effective date greater then effective date' do
        before do
          hbx_enrollment2.update_attributes(effective_on: effective_on + 1.month)
          input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should not consider second enrollment when calculating consumed amount' do
          expect(@result.success).to eq(900.00)
        end
      end
    end
  end

  context 'for prior year effective_on' do
    let(:prev_year_start_date) {year_start_date.prev_year}
    let!(:old_tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: prev_year_start_date, effective_ending_on: nil)}
    let!(:old_ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: old_tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_expired',
                              changing: false,
                              effective_on: prev_year_start_date,
                              terminated_on: nil,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    before do
      input_params = {family: family, effective_on: Date.new(prev_year_start_date.year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.success).to eq(1500.00)
    end
  end

  context 'for termination on set to end of year' do
    let(:prev_year_start_date) {year_start_date.prev_year}
    let!(:old_tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: prev_year_start_date, effective_ending_on: nil)}
    let!(:old_ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: old_tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_expired',
                              changing: false,
                              effective_on: prev_year_start_date,
                              terminated_on: nil,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    before do
      termination_date_setting = EnrollRegistry[:calculate_monthly_aggregate].settings(:termination_date)
      allow(termination_date_setting).to receive(:item).and_return('end_of_year')
      input_params = {family: family, effective_on: Date.new(prev_year_start_date.year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.success).to eq(1200.00)
    end
  end

  context 'When eligible months are considered' do
    let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: year_start_date, effective_ending_on: nil)}
    let!(:ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household)}
    let!(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        benefit_market_kind: :aca_individual,
                        kind: :health,
                        csr_variant_id: '01',
                        metal_level_kind: :silver)
    end
    let!(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_terminated',
                              kind: 'individual',
                              changing: false,
                              product: product,
                              effective_on: year_start_date,
                              terminated_on: year_start_date.end_of_month + 2.months,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    before do
      allow(@eligible_months_setting).to receive(:item).and_return(true)
    end

    context 'Family with multiple enrollment with gap in eligible coverage' do
      let!(:hbx_enrollment2) do
        enr = FactoryBot.create(:hbx_enrollment,
                                family: family,
                                household: household,
                                is_active: true,
                                aasm_state: 'coverage_selected',
                                kind: 'individual',
                                changing: false,
                                product: product,
                                effective_on: TimeKeeper.date_of_record,
                                terminated_on: nil,
                                applied_aptc_amount: 300.00)
        FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
        enr
      end

      context 'Gap in eligible months of 4months will not be considered' do
        before do
          input_params = {family: family, effective_on: Date.new(current_year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(1100.00)
        end
      end

      context 'when there is an renewal enrollment for 1/1' do
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new((current_year - 1), 11, 1))
          hbx_enrollment.update_attributes(effective_on: Date.new(current_year, 1, 1))
          input_params = {family: family, effective_on: Date.new(current_year, 1, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(500.0)
        end
      end

      context 'Gap in eligible months of 4months will not be considered and effective date is middle of month.' do
        before do
          hbx_enrollment.update_attributes(terminated_on: TimeKeeper.date_of_record - 1.day)
          input_params = {family: family, effective_on: Date.new(current_year, 11, 10), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(1711.76)
        end
      end

      context 'Gap in eligible months of 4months will not be considered and one of the enrollment is shop enrollment.' do
        before do
          hbx_enrollment.update_attributes(kind: "employer_sponsored", applied_aptc_amount: 0)
          input_params = {family: family, effective_on: Date.new(current_year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(800.00)
        end
      end

      context 'Gap in eligible months of 4months will not be considered and one of the enrollment is coverall enrollment.' do
        before do
          hbx_enrollment.update_attributes(kind: "coverall", applied_aptc_amount: 0)
          input_params = {family: family, effective_on: Date.new(current_year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(800.00)
        end
      end

      context 'Gap in eligible months of 4months will not be considered and one of the enrollment with effective date greater then effective on.' do
        before do
          hbx_enrollment2.update_attributes(effective_on: Date.new(current_year, 12, 1))
          input_params = {family: family, effective_on: Date.new(current_year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(800.00)
        end
      end


      context 'Gap in eligible months of 4months will not be considered and one of the enrollment is catastrophic enrollment.' do
        before do
          hbx_enrollment.update_attributes(applied_aptc_amount: 0)
          hbx_enrollment2.update_attributes(applied_aptc_amount: 0)
          product.update_attributes(metal_level_kind: 'catastrophic')
          input_params = {family: family, effective_on: Date.new(current_year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
          @result = subject.call(input_params)
        end

        it 'should return aptc amount based on eligible months' do
          expect(@result.success).to eq(500.00)
        end
      end
    end

    context 'Family with single enrollment with gap in eligible coverage' do

      context 'terminated_on is in future to effective_on' do
        before do
          input_params = { family: family,
                           effective_on: hbx_enrollment.terminated_on.beginning_of_month,
                           shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id),
                           subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id }
          @result = subject.call(input_params)
        end

        it 'should return aptc amount with respect to eligible months' do
          expect(@result.success).to eq(540.0)
        end
      end
    end
  end
end
