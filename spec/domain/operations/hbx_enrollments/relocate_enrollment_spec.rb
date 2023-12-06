# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RelocateEnrollment, dbclean: :after_each do

  before :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 10, 1))
  end
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:start_date) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:end_date) { (start_date + 3.months).end_of_month }
  let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile, metal_level_kind: :silver) }
  let!(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :anthm_profile)}
  let!(:service_area1) {FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "DCS001", active_year: start_date.year, issuer_profile_id: issuer_profile.id, issuer_hios_id: issuer_profile.issuer_hios_ids.first)}
  let!(:service_area2) {FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "DCS002", active_year: start_date.year, issuer_profile_id: issuer_profile.id, issuer_hios_id: issuer_profile.issuer_hios_ids.second)}
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, family: family,
                                       household: family.active_household,
                                       coverage_kind: "health",
                                       kind: "individual",
                                       aasm_state: "coverage_selected",
                                       effective_on: end_date + 1.day,
                                       product: product,
                                       consumer_role_id: person.consumer_role.id)
  end
  let!(:enrollment_members) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment, is_subscriber: true, family_member: family.family_members[0]) }

  let!(:county_zip) do
    ::BenefitMarkets::Locations::CountyZip.all.delete_all
    FactoryBot.create(:benefit_markets_locations_county_zip, zip: '04001', county_name: 'York', state: "ME")
  end
  let!(:county_zip2) { FactoryBot.create(:benefit_markets_locations_county_zip, zip: '04471', county_name: 'Aroostook', state: "ME") }
  let!(:rating_area2) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: start_date.year, county_zip_ids: [county_zip2.id], exchange_provided_code: "R-ME004", covered_states: nil)}

  context "when expected_enrollment_action is Generate Rerated Enrollment with same product ID" do

    before do
      person.home_address.update_attributes(zip: county_zip.zip, county: county_zip.county_name, state: county_zip.state)
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature).to receive(:is_enabled).and_return(true)
      BenefitMarkets::Locations::RatingArea.where(:exchange_provided_code.nin => ["R-ME004"]).first.update_attributes(covered_states: nil, active_year: start_date.year, county_zip_ids: [county_zip.id], exchange_provided_code: "R-ME001")
      BenefitMarkets::Locations::ServiceArea.update_all(covered_states: ['ME'])
      @rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
      enrollment.update_attributes!(rating_area_id: @rating_area.id)
      person.home_address.update_attributes(zip: county_zip2.zip, county: county_zip2.county_name, state: county_zip2.state)

      @params = {
        expected_enrollment_action: "Generate Rerated Enrollment with same product ID",
        enrollment_hbx_id: enrollment.hbx_id,
        is_service_area_changed: true,
        is_rating_area_changed: true,
        product_offered_in_new_service_area: true
      }

    end

    it "should generate new enrollment for ivl" do
      expect(family.active_household.hbx_enrollments.count).to eq(1)
      subject.call(@params)
      family.reload
      expect(family.active_household.hbx_enrollments.count).to eq(2)
      expect(described_class.new.call({expected_enrollment_action: "Generate Rerated Enrollment with same product ID", enrollment_hbx_id: enrollment.hbx_id})).to be_success
    end

    it "should generate new enrollment with different rating area" do
      subject.call(@params)
      family.reload
      expect(family.active_household.hbx_enrollments.map(&:rating_area_id)).to eq([@rating_area.id, rating_area2.id])
    end

    it "should generate new enrollment with different rating area" do
      subject.call(@params)
      family.reload
      date_context = ::HbxEnrollments::CalculateEffectiveOnForEnrollment.call(base_enrollment_effective_on: enrollment.effective_on, system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'))
      expect(family.active_household.hbx_enrollments.last.effective_on).to eq(date_context.new_effective_on.to_date)
    end
  end

  context "when expected_enrollment_action is Terminate Enrollment Effective End of the Month" do
    before do
      person.home_address.update_attributes(zip: county_zip.zip, county: county_zip.county_name, state: county_zip.state)
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
      BenefitMarkets::Locations::RatingArea.where(:exchange_provided_code.nin => ["R-ME004"]).first.update_attributes(covered_states: nil, active_year: start_date.year, county_zip_ids: [county_zip.id], exchange_provided_code: "R-ME001")
      BenefitMarkets::Locations::ServiceArea.update_all(covered_states: ['ME'])
      @rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
      enrollment.update_attributes!(rating_area_id: @rating_area.id)
      person.home_address.update_attributes(zip: county_zip2.zip, county: county_zip2.county_name, state: "DC")

      @params = {
        expected_enrollment_action: "Generate Rerated Enrollment with same product ID",
        enrollment_hbx_id: enrollment.hbx_id,
        is_service_area_changed: true,
        is_rating_area_changed: true,
        product_offered_in_new_service_area: true
      }
    end

    it "should terminate enrollment" do
      subject.call(@params)
      enrollment.reload
      expect(enrollment.aasm_state).to eq "coverage_terminated"
    end
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end
end
