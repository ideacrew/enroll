# frozen_string_literal: true

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

require 'rails_helper'
RSpec.describe ::Operations::HbxEnrollments::EndDateChange, dbclean: :after_each do

  subject do
    described_class.new.call(params: params)
  end

  context 'Invalid params' do
    context 'enrollment id is blank' do
      let(:params) {{}}

      it 'fails' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "enrollment_id not present"
      end
    end

    context 'termination date is blank' do
      let(:params) {{"enrollment_id" => '12345'}}
      it 'fails' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "new termination date not present"
      end
    end
  end

  context 'Invalid enrollment' do
    context 'enrollment id is blank' do
      let(:params) { { 'enrollment_id' => BSON::ObjectId.new.to_s, 'new_termination_date' => '11/10/1988' } }

      it 'fails' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq("Enrollment not found")
      end
    end
  end

  context 'Invalid enrollment aasm state' do
    let(:family)   { FactoryBot.create(:family, :with_primary_family_member) }
    let(:coverage_selected_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_selected')}
    context 'enrollment id is blank' do
      let(:params) {{"enrollment_id" => coverage_selected_enrollment.id.to_s, "new_termination_date" => "11/10/1988"}}

      it 'fails' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq("Enrollment not in valid state")
      end
    end
  end

  context 'IVL market' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_family)}
    let(:family)   { person.families.first }

    context 'current year terminated enrollment termination date is greater than enrollment termination' do
      let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_terminated', kind: 'individual', terminated_on: TimeKeeper.date_of_record.end_of_month)}
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (TimeKeeper.date_of_record.end_of_month + 10.days).to_s}}

      it 'should return failure' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq("Invalid termination date")
      end
    end

    context 'current year terminated enrollment termination date is less than than enrollment termination' do
      let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_terminated', kind: 'individual', terminated_on: TimeKeeper.date_of_record.end_of_month)}
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (TimeKeeper.date_of_record.end_of_month - 10.days).to_s}}

      it 'should return success' do
        expect(subject).to be_success
        terminated_enrollment.reload
        expect(terminated_enrollment.terminated_on).to eq TimeKeeper.date_of_record.end_of_month - 10.days
      end
    end

    context 'prior year terminated enrollment where termination date is greater than than enrollment termination' do
      include_context 'prior, current and next year benefit coverage periods and products'
      let(:address) { family.primary_person.rating_address }
      let(:current_year) { TimeKeeper.date_of_record.beginning_of_year.year }
      let!(:current_rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: current_year) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: current_year)
      end
      let!(:current_service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: current_year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: current_year)
      end

      let(:rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_date.year) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: start_date.year)
      end

      let(:service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_date.year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: start_date.year)
      end

      let(:prior_coverage_year) { Date.today.year - 1}
      let!(:prior_hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :no_open_enrollment_coverage_period,
                          coverage_year: prior_coverage_year)
      end
      let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
      let(:termination_date) { (Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).end_of_month }
      let(:product) do
        product = BenefitMarkets::Products::Product.by_year(start_date.year).first
        product.update_attributes(service_area_id: service_area.id)
        product
      end
      let(:terminated_enrollment) do
        FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_terminated', kind: 'individual', rating_area_id: rating_area.id,
                                           effective_on: start_date, terminated_on: termination_date, consumer_role_id: family.primary_person.consumer_role.id, product_id: product.id)
      end
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (termination_date + 10.days).to_s}}

      context 'no rating area found' do

        before do
          allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
          address.update_attributes(county: "Zip code outside supported area", state: 'MA')
        end

        it 'should return failure & not create enrollment' do
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
          expect(subject).not_to be_success
          expect(subject.failure).to eq('Rating Area Is Blank')
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
        end
      end

      context 'no service area found' do
        let(:setting) { double }
        before :each do
          allow(EnrollRegistry[:service_area].setting(:service_area_model)).to receive(:item).and_return('county')
          address.update_attributes(county: "Zip code outside supported area", state: 'MA')
        end

        it 'should return failure & not create enrollment' do
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
          expect(subject).not_to be_success
          expect(subject.failure).to eq('Product is NOT offered in service area')
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
        end
      end

      context 'with service & rating area' do

        it 'should return success and create a new terminated enrollment' do
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
          expect(subject).to be_success
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 2
        end
      end
    end

    context 'prior year terminated enrollment where termination date is less than than enrollment termination' do
      let(:prior_coverage_year) { Date.today.year - 1}
      let!(:prior_hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :no_open_enrollment_coverage_period,
                          coverage_year: prior_coverage_year)
      end
      let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
      let(:termination_date) { (Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).end_of_month }
      let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_terminated', kind: 'individual', effective_on: start_date, terminated_on: termination_date)}
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

      it 'should return success and create a new terminated enrollment' do
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
        expect(subject).to be_success
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
      end
    end

    context 'prior year expired enrollment where termination date is less than than enrollment expiration date' do

      before do
        allow(EnrollRegistry[:change_end_date].feature.settings.last).to receive(:item).and_return(true)
      end

      let(:prior_coverage_year) { Date.today.year - 1}
      let!(:prior_hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :no_open_enrollment_coverage_period,
                          coverage_year: prior_coverage_year)
      end
      let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
      let(:termination_date) { start_date + 2.months }
      let(:expired_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_expired', kind: 'individual', effective_on: start_date)}
      let(:params) {{ "enrollment_id" => expired_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

      it 'should return success and create a new terminated enrollment' do
        expect(expired_enrollment.family.hbx_enrollments.count).to eq 1
        expect(subject).to be_success
        expect(expired_enrollment.family.hbx_enrollments.count).to eq 1
        expired_enrollment.reload
        expect(expired_enrollment.terminated_on.present?).to eq true
      end
    end

    context 'prior year expired, current active enrollment and IVL OE renewing enrollment' do
      include_context 'prior, current and next year benefit coverage periods and products'

      before do
        allow(EnrollRegistry[:change_end_date].feature.settings.last).to receive(:item).and_return(true)
      end

      context 'prior year expired enrollment where termination date is less than than enrollment expiration date' do
        let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
        let(:termination_date) { start_date + 2.months }
        let(:expired_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_expired', kind: 'individual', effective_on: start_date, product_id: prior_product.id)}
        let(:active_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_selected', kind: 'individual', effective_on: expired_enrollment.effective_on.end_of_year.next_day,  product_id: current_product.id)}
        let!(:renewing_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'auto_renewing', kind: 'individual', effective_on: active_enrollment.effective_on.end_of_year.next_day,  product_id: renewal_product.id)}

        let(:params) {{ "enrollment_id" => expired_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

        it 'should return success and create a new terminated enrollment and also cancel active and renewing enrollments' do
          expect(expired_enrollment.family.hbx_enrollments.count).to eq 3
          expect(subject).to be_success
          expect(expired_enrollment.family.enrollments.count).to eq 1
          active_enrollment.reload
          renewing_enrollment.reload
          expect(active_enrollment.aasm_state).to eq 'coverage_canceled'
          expect(renewing_enrollment.aasm_state).to eq 'coverage_canceled'
        end
      end
    end

    context 'prior year terminated, current active enrollment and IVL OE renewing enrollment' do
      include_context 'prior, current and next year benefit coverage periods and products'
      context 'prior year terminated enrollment where termination date is less than than enrollment terminated date' do
        let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
        let(:termination_date) { start_date + 2.months }
        let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_terminated', kind: 'individual', effective_on: start_date, terminated_on: termination_date, product_id: prior_product.id)}
        let(:active_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_selected', kind: 'individual', effective_on: terminated_enrollment.effective_on.end_of_year.next_day,  product_id: current_product.id)}
        let!(:renewing_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'auto_renewing', kind: 'individual', effective_on: active_enrollment.effective_on.end_of_year.next_day,  product_id: renewal_product.id)}

        let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

        it 'should return success and terminate expired enrollment and should not cancel active and renewing enrollments' do
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 3
          expect(subject).to be_success
          expect(terminated_enrollment.family.enrollments.count).to eq 3
          active_enrollment.reload
          renewing_enrollment.reload
          expect(active_enrollment.aasm_state).to eq 'coverage_selected'
          expect(renewing_enrollment.aasm_state).to eq 'auto_renewing'
        end
      end
    end
  end

  context 'SHOP market' do
    include_context "setup benefit market with market catalogs and product packages"

    let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
    let(:coverage_kind)     { :health }
    let(:person)          { FactoryBot.create(:person) }
    let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
    let(:hired_on)        { expired_benefit_application.start_on - 10.days }

    context 'current year terminated enrollment termination date is greater than enrollment termination' do
      let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: shop_family, aasm_state: 'coverage_terminated', kind: 'employer_sponsored', terminated_on: TimeKeeper.date_of_record.end_of_month)}
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (TimeKeeper.date_of_record.end_of_month + 10.days).to_s}}

      it 'should return failure' do
        expect(subject).not_to be_success
        expect(subject.failure).to eq("Invalid termination date")
      end
    end

    context 'current year terminated enrollment termination date is less than than enrollment termination' do
      let(:terminated_enrollment) {FactoryBot.create(:hbx_enrollment, family: shop_family, aasm_state: 'coverage_terminated', kind: 'employer_sponsored', terminated_on: TimeKeeper.date_of_record.end_of_month)}
      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (TimeKeeper.date_of_record.end_of_month - 10.days).to_s}}

      it 'should return success' do
        expect(subject).to be_success
        terminated_enrollment.reload
        expect(terminated_enrollment.terminated_on).to eq TimeKeeper.date_of_record.end_of_month - 10.days
      end
    end

    context 'prior year shop terminated enrollment where termination date is greater than than enrollment termination but less than application termination' do
      include_context "setup terminated and active benefit applications"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:termination_date) {(terminated_benefit_application.end_on - 1.month)}
      let!(:terminated_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: terminated_benefit_application.start_on,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: terminated_benefit_package.id,
                          sponsored_benefit_id: terminated_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: terminated_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_terminated',
                          terminated_on: termination_date)
      end


      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => termination_date.next_day.to_s}}

      it 'should return success and create a new terminated enrollment' do
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
        expect(subject).to be_success
        terminated_enrollment.reload
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 2
        expect(terminated_enrollment.family.hbx_enrollments.map(&:aasm_state)).to match_array(['coverage_terminated', 'coverage_terminated'])
      end
    end

    context 'prior year shop terminated enrollment where termination date is less than than enrollment termination' do
      include_context "setup terminated and active benefit applications"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:termination_date) {(terminated_benefit_application.start_on + 1.month)}
      let!(:terminated_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: terminated_benefit_application.start_on,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: terminated_benefit_package.id,
                          sponsored_benefit_id: terminated_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: terminated_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_terminated',
                          terminated_on: termination_date)
      end


      let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (terminated_enrollment.terminated_on - 10.days).to_s}}

      it 'should return success and should not create a new terminated enrollment' do
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
        expect(subject).to be_success
        terminated_enrollment.reload
        expect(terminated_enrollment.family.hbx_enrollments.count).to eq 1
      end
    end

    context 'prior year SHOP expired enrollment where termination date is less than than enrollment expiration date' do

      before do
        allow(EnrollRegistry[:change_end_date].feature.settings.last).to receive(:item).and_return(true)
      end

      include_context "setup expired, and active benefit applications"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:termination_date) {(expired_benefit_application.end_on - 1.month)}
      let!(:expired_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application.start_on,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_expired')
      end

      let(:params) {{ "enrollment_id" => expired_enrollment.id.to_s, "new_termination_date" => termination_date.to_s}}

      it 'should return success and should terminate expired enrollment' do
        expect(expired_enrollment.family.hbx_enrollments.count).to eq 1
        expect(subject).to be_success
        expect(expired_enrollment.family.hbx_enrollments.count).to eq 1
        expired_enrollment.reload
        expect(expired_enrollment.aasm_state).to eq 'coverage_terminated'
      end
    end

    context 'prior year expired, current active enrollment and SHOP OE renewing enrollment' do
      include_context 'setup expired, active and renewing benefit applications'

      before do
        allow(EnrollRegistry[:change_end_date].feature.settings.last).to receive(:item).and_return(true)
      end

      context 'prior year expired enrollment where termination date is less than than enrollment expiration date' do
        let!(:current_benefit_market_catalog) do
          ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
            site,
            benefit_market,
            (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
          )
          benefit_market.benefit_market_catalogs.where(
            "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
          ).first
        end
        let(:start_date) {(Date.new(TimeKeeper.date_of_record.year, 11,1) - 1.year).beginning_of_month}
        let(:termination_date) { start_date + 2.months }
        let!(:expired_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: expired_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: expired_benefit_package.id,
                            sponsored_benefit_id: expired_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: expired_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_expired')
        end
        let!(:active_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: active_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: active_benefit_package.id,
                            sponsored_benefit_id: active_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: active_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_selected')
        end
        let!(:renewing_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: renewal_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: renewal_benefit_package.id,
                            sponsored_benefit_id: renewal_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: renewal_sponsored_benefit.reference_product.id,
                            aasm_state: 'auto_renewing')
        end

        let(:params) {{ "enrollment_id" => expired_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

        it 'should return success and terminated expired enrollment and also cancel active and renewing enrollments' do
          expect(expired_enrollment.family.hbx_enrollments.count).to eq 3
          expect(subject).to be_success
          expect(expired_enrollment.family.enrollments.count).to eq 1
          active_enrollment.reload
          renewing_enrollment.reload
          expect(active_enrollment.aasm_state).to eq 'coverage_canceled'
          expect(renewing_enrollment.aasm_state).to eq 'coverage_canceled'
        end
      end
    end

    context 'prior year terminated, current active enrollment and SHOP OE renewing enrollment' do
      include_context 'setup expired, active and renewing benefit applications'
      context 'prior year terminated enrollment where termination date is less than than enrollment terminated date' do
        let!(:current_benefit_market_catalog) do
          ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
            site,
            benefit_market,
            (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
          )
          benefit_market.benefit_market_catalogs.where(
            "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
          ).first
        end

        let(:terminated_benefit_application) do
          termination_date = expired_benefit_application.start_on + 5.months
          effective_period = expired_benefit_application.start_on..termination_date
          expired_benefit_application.update_attributes(aasm_state: :terminated, effective_period: effective_period)
          expired_benefit_application
        end

        let(:terminated_benefit_package) { terminated_benefit_application.benefit_packages[0] }
        let(:terminated_sponsored_benefit) { terminated_benefit_package.sponsored_benefit_for(coverage_kind) }

        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
        let(:termination_date) {(terminated_benefit_application.start_on + 1.month)}
        let!(:terminated_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: terminated_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: terminated_benefit_package.id,
                            sponsored_benefit_id: terminated_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: terminated_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_terminated',
                            terminated_on: termination_date)
        end

        let!(:active_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: active_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: active_benefit_package.id,
                            sponsored_benefit_id: active_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: active_sponsored_benefit.reference_product.id,
                            aasm_state: 'coverage_selected')
        end

        let!(:renewing_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            family: shop_family,
                            coverage_kind: coverage_kind,
                            effective_on: renewal_benefit_application.start_on,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: renewal_benefit_package.id,
                            sponsored_benefit_id: renewal_sponsored_benefit.id,
                            employee_role_id: employee_role.id,
                            benefit_group_assignment: census_employee.active_benefit_group_assignment,
                            product_id: renewal_sponsored_benefit.reference_product.id,

                            aasm_state: 'auto_renewing')
        end
        let(:params) {{ "enrollment_id" => terminated_enrollment.id.to_s, "new_termination_date" => (termination_date - 10.days).to_s}}

        it 'should return success and terminate expired enrollment and should not cancel active and renewing enrollments' do
          expect(terminated_enrollment.family.hbx_enrollments.count).to eq 3
          expect(subject).to be_success
          expect(terminated_enrollment.family.enrollments.count).to eq 3
          active_enrollment.reload
          renewing_enrollment.reload
          expect(active_enrollment.aasm_state).to eq 'coverage_selected'
          expect(renewing_enrollment.aasm_state).to eq 'auto_renewing'
        end
      end
    end
  end
end
