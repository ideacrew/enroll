# frozen_string_literal: true

require 'rails_helper'

module Insured
  RSpec.describe Factories::SelfServiceFactory, type: :model, dbclean: :after_each do

    before :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
      DatabaseCleaner.clean
      allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
    end

    let(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
    let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
    let(:sbc_document) {FactoryBot.build(:document, subject: 'SBC', identifier: 'urn:openhbx#123')}
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, title: 'AAA', issuer_profile_id: 'ab1233', metal_level_kind: :silver, benefit_market_kind: :aca_individual, sbc_document: sbc_document)}
    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) do
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record, hbx_enrollment: enrollment, coverage_start_on: TimeKeeper.date_of_record, tobacco_use: 'N')
    end
    let!(:hbx_enrollment_member2) do
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: enrollment, tobacco_use: 'N')
    end
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}

    subject { Insured::Factories::SelfServiceFactory }

    describe "view methods" do
      before :each do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual, metal_level_kind: {"$ne" => "catastrophic"}).first
        @product.update_attributes(ehb: 0.9844)
        enrollment.update_attributes(product: @product)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members.detect { |fm| !fm.is_primary_applicant }.person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      context "#find" do
        before :each do
          family.special_enrollment_periods << sep
          @enrollment_id = enrollment.id
          @family_id     = family.id
          @qle           = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))
        end

        it "returns a hash of valid params" do
          @form_params = subject.find(@enrollment_id, @family_id)
          expect(@form_params[:enrollment]).to eq enrollment
          expect(@form_params[:family]).to eq family
          expect(@form_params[:qle]).to eq @qle
        end

        it "returns a falsey is_aptc_eligible if latest_active_tax_household does not exist" do
          @form_params = subject.find(@enrollment_id, @family_id)
          expect(@form_params[:is_aptc_eligible]).to be_falsey
        end

        it "returns a truthy is_aptc_eligible if tax household and valid aptc members exist" do
          tax_household = FactoryBot.create(:tax_household, household: family.active_household)
          FactoryBot.create(:tax_household_member, tax_household: tax_household)
          form_params = subject.find(@enrollment_id, @family_id)
          expect(form_params[:is_aptc_eligible]).to be_truthy
        end
      end
    end

    describe "#validate_rating_address" do

      context "#validate_rating_address with valid rating address" do
        before do
          @family_id     = family.id
        end

        it "returns true with valid rating address" do
          result = subject.new({family_id: @family_id}).validate_rating_address
          expect(result).to be_truthy
        end
      end

      context "#validate_rating_address with invalid rating address" do
        let(:person1) {FactoryBot.create(:person, addresses: nil)}
        let(:family1) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person1)}
        let(:message) {l10n("insured.out_of_state_error_message")}
        before :each do
          family1.primary_person.rating_address.destroy!
          family1.save!
        end

        it "returns a failure message with invalid rating address" do
          family1.primary_person.rating_address.destroy!
          result = subject.new({family_id: family1.id}).validate_rating_address
          expect(result).to include(message)
        end
      end
    end

    describe "post methods" do
      before :all do
        DatabaseCleaner.clean
      end

      let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", metal_level_kind: :silver, issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month) }

      context "#term_or_cancel" do
        it "should cancel an enrollment if it is not yet effective" do
          subject.term_or_cancel(enrollment_to_cancel.id, TimeKeeper.date_of_record, 'cancel')
          enrollment_to_cancel.reload
          expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
        end

        it "should terminate an enrollment if it is already effective" do
          subject.term_or_cancel(enrollment_to_term.id, TimeKeeper.date_of_record, 'terminate')
          enrollment_to_term.reload
          expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
        end
      end
    end

    describe "update_enrollment_for_apcts when apply_aggregate_to_enrollment feature is disabled" do
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}


      before :each do
        allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844, is_hc4cc_plan: true)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 646.72)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: TimeKeeper.date_of_record)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 59.years))
        allow(enrollment).to receive(:is_eligible_for_osse_grant?).and_return(true)
      end

      it 'should return updated enrollment with aptc fields' do
        subject.update_enrollment_for_apcts(enrollment, 2000)
        enrollment.reload
        expect(enrollment.applied_aptc_amount.to_f).to eq 1274.44
        expect(enrollment.elected_aptc_pct).to eq 0.63722
      end

      it 'should correctly update applied aptc amount if elected aptc is higher than product premium' do
        subject.update_enrollment_for_apcts(enrollment, 5000)
        enrollment.reload
        expect(enrollment.applied_aptc_amount.to_f).to eq 1274.44
        expect(enrollment.elected_aptc_pct).to eq 0.63722
      end

      it 'should correctly update applied aptc amount if elected aptc is lower than product premium' do
        subject.update_enrollment_for_apcts(enrollment, 500)
        enrollment.reload
        expect(enrollment.applied_aptc_amount.to_f).to eq 500
        expect(enrollment.elected_aptc_pct).to eq 0.25
      end

      it 'should set eligible child care subsidy amount' do
        expect(enrollment.product.is_hc4cc_plan).to be_truthy
        subject.update_enrollment_for_apcts(enrollment, 500)
        enrollment.reload
        expect(enrollment.product.is_hc4cc_plan).to be_truthy
        expected_subsidy = enrollment.total_premium.to_f - enrollment.applied_aptc_amount.to_f
        expect(enrollment.eligible_child_care_subsidy.to_f).to eq expected_subsidy.round(2)
      end

      context 'when product is not hc4cc true' do
        it 'does set eligible child care subsidy amount to zero' do
          @product.update_attributes(is_hc4cc_plan: false)
          expect(enrollment.product.is_hc4cc_plan).to be_falsey
          subject.update_enrollment_for_apcts(enrollment, 500)
          enrollment.reload
          expect(enrollment.product.is_hc4cc_plan).to be_falsey
          expect(enrollment.eligible_child_care_subsidy.to_f).to eq 0.0
        end
      end
    end

    describe "update_enrollment_for_apcts when apply_aggregate_to_enrollment feature is enabled" do
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 300.0)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}

      before :each do
        allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(true)
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9966)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: TimeKeeper.date_of_record.beginning_of_month)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
        person.update_attributes!(dob: (enrollment.effective_on - 32.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 61.years))
      end

      it 'should return updated enrollment with aptc fields' do
        subject.update_enrollment_for_apcts(enrollment, 255.0)
        enrollment.reload
        expect(enrollment.applied_aptc_amount.to_f).to eq 255.0
        expect(enrollment.elected_aptc_pct).to eq 0.85
      end
    end

    describe "#update_aptc" do
      let(:address) { family.primary_person.rating_address }
      let(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }
      let(:application_period) { effective_date.beginning_of_year..effective_date.end_of_year }
      let(:rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_date.year)
      end
      let(:service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_date.year)
      end
      let!(:renewal_rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: renewal_calender_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: renewal_calender_date.year)
      end
      let!(:renewal_service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: renewal_calender_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: renewal_calender_date.year)
      end

      let!(:product) do
        prod =
          FactoryBot.create(
            :benefit_markets_products_health_products_health_product,
            :with_issuer_profile,
            :silver,
            benefit_market_kind: :aca_individual,
            kind: :health,
            application_period: application_period,
            service_area: service_area,
            csr_variant_id: '01',
            renewal_product_id: renewal_individual_health_product.id
          )
        prod.premium_tables = [premium_table]
        prod.save
        prod
      end
      let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
      let(:renewal_calender_date) { TimeKeeper.date_of_record.beginning_of_year.next_year }
      let(:renewal_application_period) { renewal_calender_date.beginning_of_year..renewal_calender_date.end_of_year }
      let!(:renewal_individual_health_product) do
        prod =
          FactoryBot.create(
            :benefit_markets_products_health_products_health_product,
            :with_issuer_profile,
            :silver,
            benefit_market_kind: :aca_individual,
            kind: :health,
            service_area: renewal_service_area,
            csr_variant_id: '01',
            application_period: renewal_application_period
          )
        prod.premium_tables = [renewal_individual_premium_table]
        prod.save
        prod
      end

      let(:renewal_individual_premium_table) { build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area) }

      before :each do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 12, 15))
        effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
        tax_household10 = FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil, effective_starting_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
        eligibility_determination = FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000, determined_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
        tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)
        tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)

        @product = product
        service_area = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on.year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
        @product.update_attributes(ehb: 0.9844, application_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year, service_area_id: service_area.id)
        premium_table = @product.premium_tables.first
        premium_table.update_attributes(effective_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: effective_on, aasm_state: "auto_renewing")
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
        cr1 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
        family.family_members[1].person.consumer_role = cr1
        cr2 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
        family.family_members[2].person.consumer_role = cr2

        family.save!
      end

      describe 'when multi tax household enabled' do
        before do
          allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)

          allow(::Operations::PremiumCredits::FindAptc).to receive(:new).and_return(
            double(
              call: double(
                success?: true,
                value!: max_aptc
              )
            )
          )
          allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 1500, total_premium: 1600, total_childcare_subsidy_amount: 0))
        end

        let(:max_aptc) { 1200.0 }

        it 'returns new enrollment with newly determined aptc' do
          subject.update_aptc(enrollment.id, nil, elected_aptc_pct: 0.85)
          enrollment.reload
          expect(enrollment.aasm_state).to eq 'coverage_canceled'
          new_enrollment = family.reload.active_household.hbx_enrollments.last
          expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
          expect(new_enrollment.elected_aptc_pct).to eq(0.85)
          expect(new_enrollment.applied_aptc_amount.to_f).to eq(1020.0)
          expect(new_enrollment.ehb_premium.to_f).to eq(1500.0)
        end

        context 'when elected_aptc_pct exists' do

          it 'creates enrollment with elected_aptc_pct' do
            subject.update_aptc(enrollment.id, nil, elected_aptc_pct: 0.5)
            new_enrollment = family.reload.active_household.hbx_enrollments.last
            expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
            expect(new_enrollment.elected_aptc_pct).to eq(0.5)
            expect(new_enrollment.applied_aptc_amount.to_f).to eq(600.0)
            expect(new_enrollment.ehb_premium.to_f).to eq(1500.0)
          end
        end

        context 'when elected_aptc_pct not exists' do
          context 'when elected_aptc_pct '
          it 'creates enrollment with default elected_aptc_pct' do
            subject.update_aptc(enrollment.id, nil)
            new_enrollment = family.reload.active_household.hbx_enrollments.last
            expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
            expect(new_enrollment.elected_aptc_pct).to eq(0.0)
            expect(new_enrollment.applied_aptc_amount.to_f).to eq(0.0)
            expect(new_enrollment.ehb_premium.to_f).to eq(1500.0)
          end
        end

        context 'when elected_aptc_pct is 0' do
          it 'creates enrollment with 0 for elected_aptc_pct' do
            subject.update_aptc(enrollment.id, 0.0, elected_aptc_pct: 0.0)
            new_enrollment = family.reload.active_household.hbx_enrollments.last
            expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
            expect(new_enrollment.elected_aptc_pct).to eq(0.0)
            expect(new_enrollment.applied_aptc_amount.to_f).to eq(0.0)
          end
        end

        context 'when ehb premium less than aptc' do
          before do
            effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
            allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 393.76, total_premium: 410, total_childcare_subsidy_amount: 0))
          end

          it 'creates enrollment with ehb premium' do
            subject.update_aptc(enrollment.id, nil, elected_aptc_pct: 1)
            new_enrollment = family.reload.active_household.hbx_enrollments.last
            expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
            expect(new_enrollment.applied_aptc_amount.to_f).to eq(393.76)
            expect(new_enrollment.ehb_premium.to_f).to eq(393.76)
          end
        end
      end

      describe "update enrollment for renewing enrollments" do
        it 'should return the updated enrollment' do
          subject.update_aptc(enrollment.id, 1000)
          enrollment.reload
          family.reload
          expect(enrollment.aasm_state).to eq "coverage_canceled"
          expect(family.active_household.hbx_enrollments.last.aasm_state).to eq "coverage_selected"
        end

        context 'for nil rating area' do
          before :each do
            allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
            allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
            person.addresses.update_all(county: "Zip code outside supported area")
            ::BenefitMarkets::Locations::RatingArea.all.update_all(covered_states: nil)
          end

          it 'should not create new enrollment' do
            expect(family.active_household.hbx_enrollments.count).to eq 1
            expect { subject.update_aptc(enrollment.id, 1000) }.to raise_error
            enrollment.reload
            family.reload
            expect(family.active_household.hbx_enrollments.count).to eq 1
          end
        end

        context 'for nil service area' do
          let(:setting) { double }
          before :each do
            allow(EnrollRegistry).to receive(:[]).with(:service_area).and_return(setting)
            allow(setting).to receive(:settings).with(:service_area_model).and_return(double(item: 'county'))
          end

          it 'should not create new enrollment and raises error' do
            expect(family.active_household.hbx_enrollments.count).to eq 1
            expect { subject.update_aptc(enrollment.id, 1000) }.to raise_error
            enrollment.reload
            family.reload
            expect(family.active_household.hbx_enrollments.count).to eq 1
          end
        end
      end

      describe "for invalid members" do
        before :each do
          coverage_start_on = enrollment.hbx_enrollment_members.first.coverage_start_on
          FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[2].id, eligibility_date: coverage_start_on, coverage_start_on: coverage_start_on, hbx_enrollment: enrollment, tobacco_use: 'N')
          allow(EnrollRegistry[:check_enrollment_member_eligibility].feature).to receive(:is_enabled).and_return(true)
        end

        context 'when one of the member is not applying for coverage' do
          it 'should reinstate enrollment with 2 valid members' do
            expect(enrollment.hbx_enrollment_members.count).to eq 3
            family.family_members[2].person.consumer_role.update_attributes!(is_applying_coverage: false)
            subject.update_aptc(enrollment.id, 1000)
            enrollment.reload
            family.reload
            expect(enrollment.aasm_state).to eq "coverage_canceled"
            expect(family.active_household.hbx_enrollments.last.aasm_state).to eq "coverage_selected"
            expect(family.active_household.hbx_enrollments.last.hbx_enrollment_members.count).to eq 2
          end
        end

        context 'when one of the member is incarcerated' do
          it 'should reinstate enrollment with 2 valid members' do
            expect(enrollment.hbx_enrollment_members.count).to eq 3
            family.family_members[2].person.update_attributes!(is_incarcerated: true)
            subject.update_aptc(enrollment.id, 1000)
            enrollment.reload
            family.reload
            expect(enrollment.aasm_state).to eq "coverage_canceled"
            expect(family.active_household.hbx_enrollments.last.aasm_state).to eq "coverage_selected"
            expect(family.active_household.hbx_enrollments.last.hbx_enrollment_members.count).to eq 2
          end
        end

        context 'when one of the member is not_lawfully_present' do
          it 'should reinstate enrollment with 2 valid members' do
            expect(enrollment.hbx_enrollment_members.count).to eq 3
            family.family_members[2].person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: "not_lawfully_present_in_us")
            subject.update_aptc(enrollment.id, 1000)
            enrollment.reload
            family.reload
            expect(enrollment.aasm_state).to eq "coverage_canceled"
            expect(family.active_household.hbx_enrollments.last.aasm_state).to eq "coverage_selected"
            expect(family.active_household.hbx_enrollments.last.hbx_enrollment_members.count).to eq 2
          end
        end
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end
    end

    describe "build_form_params" do
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}
      let(:applied_aptc_amount) { 120.78 }

      let(:future_effective_date) { Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date }

      before :each do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 646.72)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: TimeKeeper.date_of_record, applied_aptc_amount: applied_aptc_amount)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      it 'should return default_tax_credit_value' do
        # monthly aggregate should be applied for enrollments within the same coverage year
        if future_effective_date.year == enrollment.effective_on.year
          params = subject.find(enrollment.id, family.id)
          expect(params[:default_tax_credit_value]).to eq applied_aptc_amount
        end
      end

      it 'should return available_aptc' do
        # monthly aggregate should be applied for enrollments within the same coverage year
        if future_effective_date.year == enrollment.effective_on.year
          params = subject.find(enrollment.id, family.id)
          expect(params[:available_aptc]).to eq 1274.44
        end
      end

      it 'should return elected_aptc_pct' do
        # monthly aggregate should be applied for enrollments within the same coverage year
        if future_effective_date.year == enrollment.effective_on.year
          params = subject.find(enrollment.id, family.id)
          expect(params[:elected_aptc_pct]).to eq 0.09
        end
      end

      context "when MTHH is enabled" do
        let(:max_aptc) { 1700.0 }

        before do
          allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)

          allow(::Operations::PremiumCredits::FindAptc).to receive(:new).and_return(
            double(
              call: double(
                success?: true,
                value!: max_aptc
              )
            )
          )
          allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 1500, total_premium: 1600))
        end

        it 'should return minimum value between max aptc and total ehb premium of enrollment as available aptc' do
          params = subject.find(enrollment.id, family.id)
          expect(params[:available_aptc]).to eq 1500.0
        end

        it 'should return max tax credit' do
          params = subject.find(enrollment.id, family.id)
          expect(params[:max_tax_credit]).to eq 1700.0
        end
      end
    end

    describe "find_enrollment_effective_on_date" do
      # prospective year enrollment effective_on date
      context "within OE before last month's IndividualEnrollmentDueDayOfMonth" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 11, 1)..Date.new(current_year, 12, 1))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 2, 1)).to_date
        end

        it 'should return start of next year as effective date' do
          expect(@effective_date).to eq(Date.today.next_year.beginning_of_year)
        end
      end

      context "within OE before last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 12, 1)..Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 1, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 1, 1))
        end
      end

      context "within OE before last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with effective date 2/1" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 12, 1)..Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 2, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 1, 1))
        end
      end

      context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 1, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth and has a 2/1 effective_date" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 2, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "within OE before last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth and has a 3/1 effective_date" do # for scenarios when there is any bad data and we try to re-shop
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year, 12, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.next_year.year, 3, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "within OE last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year.next, 1, 1)..Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 1, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "within OE last month and before monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with effective date 2/1" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year.next, 1, 1)..Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 2, 1)).to_date
        end

        it 'should return start of as 2/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 2, 1)).to_date
        end

        it 'should return start of as 3/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 3, 1))
        end
      end

      context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 3/1" do
        before do
          current_year = Date.today.year
          system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 3, 1)).to_date
        end

        it 'should return start of as 3/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 3, 1))
        end
      end

      context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 1/1 and 15 day disabled" do
        before do
          allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
          system_date = Date.new(Date.today.year, 12, Settings.aca.individual_market.monthly_enrollment_due_on.next)
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(Date.today.year.next, 1, 1)).to_date
        end

        it 'should return start of as 1/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 1, 1))
        end
      end

      context "within OE last month and after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth effective date 3/1 with override" do
        before do
          allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
          current_year = Date.today.year
          system_date = rand(Date.new(current_year.next, 1, Settings.aca.individual_market.monthly_enrollment_due_on.next)..Date.new(current_year.next, 1, 31))
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 3, 1)).to_date
        end

        it 'should return start of as 3/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year.next, 2, 1))
        end
      end

      context "outside OE after monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with override enabled" do
        before do
          allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
          current_year = Date.today.year
          system_date = Date.new(current_year, 2, Settings.aca.individual_market.monthly_enrollment_due_on.next)
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), system_date).to_date
        end

        it 'should return start of as 3/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year, 3, 1))
        end
      end

      context "outside OE on monthly_enrollment_due_on day of the month of IndividualEnrollmentDueDayOfMonth with override enabled" do
        before do
          allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
          current_year = Date.today.year
          system_date = Date.new(current_year, 1, Settings.aca.individual_market.monthly_enrollment_due_on)
          allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
          @effective_date = described_class.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), Date.new(system_date.year, 1, 31)).to_date
        end

        it 'should return start of as 3/1' do
          expect(@effective_date).to eq(Date.new(Date.today.year, 2, 1))
        end
      end
    end

    after(:all) do
      DatabaseCleaner.clean
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end
  end
end
