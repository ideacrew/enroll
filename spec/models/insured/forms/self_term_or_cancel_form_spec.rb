# frozen_string_literal: true

require 'rails_helper'

module Insured
  RSpec.describe Forms::SelfTermOrCancelForm, type: :model, dbclean: :after_each do

    before do
      DatabaseCleaner.clean
      EnrollRegistry[:apply_aggregate_to_enrollment].feature.stub(:is_enabled).and_return(false)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 11,1) + 14.days)
    end

    after do
      allow(TimeKeeper).to receive(:date_of_record).and_call_original
    end

    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
    end

    let(:start_on) { TimeKeeper.date_of_record }
    let(:address) { person.rating_address }
    let(:application_period) { start_on.beginning_of_year..start_on.end_of_year }

    let!(:product) do
      prod = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                               :with_issuer_profile,
                               benefit_market_kind: :aca_individual,
                               kind: :health,
                               service_area: service_area,
                               csr_variant_id: '01',
                               metal_level_kind: 'silver',
                               application_period: application_period)
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end

    let!(:product1) do
      prod = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                               :with_issuer_profile,
                               benefit_market_kind: :aca_individual,
                               kind: :health,
                               service_area: service_area,
                               csr_variant_id: '05',
                               metal_level_kind: 'silver',
                               application_period: application_period)
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end

    let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

    let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
    let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 1.day), hbx_enrollment: enrollment)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 1.day), hbx_enrollment: enrollment)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
    let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
    let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}
    let(:applied_aptc_amount) { 120.78 }
    let(:primary_person_age) { hbx_enrollment_member1.age_on_effective_date }
    let(:hbx_enrollment_member_2_age) { hbx_enrollment_member2.age_on_effective_date }

    subject { Insured::Forms::SelfTermOrCancelForm.new }

    describe "model attributes" do
      it {
        [:carrier_logo, :enrollment, :family, :is_aptc_eligible, :market_kind, :product, :term_date].each do |key|
          expect(subject.attributes.key?(key)).to be_truthy
        end
      }
    end

    describe "validate Form" do

      let(:valid_params) do
        {
          :market_kind => "kind"
        }
      end

      let(:invalid_params) do
        {
          :market_kind => nil
        }
      end

      context "with invalid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(invalid_params)}

        it "should return false" do
          expect(build_self_term_or_cancel_form.valid?).to be_falsey
        end
      end

      context "with valid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(valid_params)}

        it "should return true" do
          expect(build_self_term_or_cancel_form.valid?).to be_truthy
        end
      end
    end

    describe "#for_view" do
      before(:each) do
        # This effective on mock to compensate for new yaers
        enrollment.update_attributes!(effective_on: TimeKeeper.date_of_record - 1.day) if enrollment.effective_on.year != TimeKeeper.date_of_record.year
        @product = product
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: hbx_enrollment_member_2_age).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: primary_person_age).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, applied_aptc_amount: applied_aptc_amount)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        site_key = EnrollRegistry[:enroll_app].setting(:site_key).item.upcase
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, hbx_enrollment_member_2_age, "R-#{site_key}001", 'NA').and_return(814.85)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, primary_person_age, "R-#{site_key}001", 'NA').and_return(879.8)
      end

      it 'should create a valid form for the view' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(Insured::Forms::SelfTermOrCancelForm.self_term_or_cancel_service(attrs)).to be_instance_of(Insured::Services::SelfTermOrCancelService)
        expect(form.enrollment).not_to be nil
        expect(form.family).not_to be nil
        expect(form.product).not_to be nil
      end

      it 'should return available_aptc' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        # TODO: Not sure about these values
        # expect(form.available_aptc).to eq 1668.2
        expect(form.available_aptc).to eq(1732.14)
      end

      it 'should return default_tax_credit_value' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(form.default_tax_credit_value).to eq applied_aptc_amount
      end

      it 'should return new_enrollment_premium' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        # TODO: Not sure about these values
        # expect(form.new_enrollment_premium).to eq 1573.87
        expect(form.new_enrollment_premium).to eq(1638.82)
      end
    end

    describe "#for_aptc_update_post" do
      before(:each) do
        enrollment.update_attributes!(effective_on: TimeKeeper.date_of_record - 1.day) if enrollment.effective_on.year != TimeKeeper.date_of_record.year
        tax_household_member1.update_attributes(csr_percent_as_integer: 87)
        tax_household_member2.update_attributes(csr_percent_as_integer: 87)
        enrollment.update_attributes(product: product, applied_aptc_amount: applied_aptc_amount)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: product.id)}
      end

      it 'should create a new enrollment with same variant when the hios_id does not match' do
        family.special_enrollment_periods << sep
        expect(family.hbx_enrollments.size).to eq 1
        expect(family.hbx_enrollments.first.product.csr_variant_id).to eq '01'
        attrs = {enrollment_id: enrollment.id, elected_aptc_pct: 1.0, aptc_applied_total: applied_aptc_amount}
        Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
        expect(family.hbx_enrollments.size).to eq 2
        expect(family.hbx_enrollments.last.product.csr_variant_id).to eq '01'
      end

      context 'Hios id of the product match for a different variant' do
        before(:each) do
          new_hios_id = "#{product.hios_base_id}-#{product1.csr_variant_id}"
          product1.update_attributes(hios_base_id: product.hios_base_id, hios_id: new_hios_id)
          product1.save!
        end

        it 'should create a new enrollment with different variant when the hios_id match' do
          family.special_enrollment_periods << sep
          expect(family.hbx_enrollments.size).to eq 1
          expect(family.hbx_enrollments.first.product.csr_variant_id).to eq '01'
          attrs = {enrollment_id: enrollment.id, elected_aptc_pct: 1.0, aptc_applied_total: applied_aptc_amount}
          Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
          expect(family.hbx_enrollments.size).to eq 2
          expect(family.hbx_enrollments.to_a.last.product.csr_variant_id).to eq '05'
        end
      end
    end

    describe "#for_post" do
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#124") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today) }

      it "should cancel an enrollment if it is not yet effective" do
        attrs = {enrollment_id: enrollment_to_cancel.id, term_date: TimeKeeper.date_of_record.to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_cancel.reload
        expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
      end

      it "should terminate an enrollment if it is already effective" do
        attrs = {enrollment_id: enrollment_to_term.id, term_date: (TimeKeeper.date_of_record + 1.month + 16.days).to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_term.reload
        expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
      end
    end

  end
end
