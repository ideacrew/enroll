# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::RelocateEnrolledProducts, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
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
    FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, coverage_kind: "health", kind: "individual", aasm_state: "coverage_selected", effective_on: end_date + 1.day, :product => product)
  end
  let!(:enrollment_members) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment, is_subscriber: true, family_member: family.family_members[0]) }
  let!(:enrollment2) do
    FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, coverage_kind: "health", kind: "individual", aasm_state: "coverage_termination_pending", effective_on: start_date, terminated_on: end_date,
                                       :product => product)
  end
  let!(:enrollment_members2) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment2, is_subscriber: true, family_member: family.family_members[0]) }
  let!(:county_zip) do
    ::BenefitMarkets::Locations::CountyZip.all.update_all(county_name: 'York',zip: "04007", state: "ME")
    ::BenefitMarkets::Locations::CountyZip.all.first
  end

  let!(:county_zip2) { FactoryBot.create(:benefit_markets_locations_county_zip, zip: '04471', county_name: 'Aroostook', state: "ME") }
  let!(:rating_area2) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: start_date.year, county_zip_ids: [county_zip2.id], exchange_provided_code: "R-ME004", covered_states: nil)}

  let!(:original_address) do
    person.home_address.update_attributes(zip: county_zip.zip, county: county_zip.county_name, state: county_zip.state)
    person.home_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
  end

  context "when zip and county is changed" do
    before do
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
      BenefitMarkets::Locations::RatingArea.update_all(covered_states: nil)
      BenefitMarkets::Locations::RatingArea.where(:exchange_provided_code.nin => ["R-ME004"]).first.update_attributes(covered_states: nil, active_year: start_date.year, county_zip_ids: [county_zip.id], exchange_provided_code: "R-ME001")
      BenefitMarkets::Locations::ServiceArea.update_all(covered_states: ['ME'])

      rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
      enrollment.update_attributes!(rating_area_id: rating_area.id)
      enrollment2.update_attributes!(rating_area_id: rating_area.id)
      person.home_address.update_attributes(zip: "04771", county: "Aroostook", state: "ME")
      modified_address = person.home_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
      @params = {
        address_set: {original_address: original_address,
                      modified_address: modified_address},
        change_set: {"old_set": {zip: county_zip.zip, county: county_zip.county_name},"new_set": {zip: "04771", county: "Aroostook"}},
        person_hbx_id: person.hbx_id,
        primary_family_id: person.primary_family.id,
        is_primary: person.primary_family.present?
      }
      @result = subject.call(@params)
    end

    it "should return success" do
      expect(@result).to be_success
    end

    it "should return rating area changed" do
      expect(@result.success[enrollment2.hbx_id][:event_outcome]).to eq "rating_area_changed"
    end
  end

  context "when state is changed" do
    before do
      allow(EnrollRegistry[:service_area].setting(:service_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
      BenefitMarkets::Locations::RatingArea.update_all(covered_states: ['ME'])
      BenefitMarkets::Locations::ServiceArea.all.update_all(covered_states: ['ME'])

      rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
      enrollment.update_attributes!(rating_area_id: rating_area.id)
      enrollment2.update_attributes!(rating_area_id: rating_area.id)
      person.home_address.update_attributes(zip: "01001", county: "test", state: "AZ")
      modified_address = person.home_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
      @params = {
        address_set: {original_address: original_address,
                      modified_address: modified_address},
        change_set: {"old_set": {"state": "MT"},"new_set": {"state": "MA"}},
        person_hbx_id: person.hbx_id,
        primary_family_id: person.primary_family.id,
        is_primary: person.primary_family.present?
      }

      @result = subject.call(@params)
    end

    it "should return success" do
      expect(@result).to be_success
    end

    it "should return service area changed" do
      expect(@result.success[enrollment2.hbx_id][:event_outcome]).to eq "service_area_changed"
    end
  end

  context "when state is changed for mailing address" do
    before do
      allow(EnrollRegistry[:service_area].setting(:service_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
      allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
      BenefitMarkets::Locations::RatingArea.update_all(covered_states: ['ME'])
      BenefitMarkets::Locations::ServiceArea.all.update_all(covered_states: ['ME'])

      rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
      enrollment.update_attributes!(rating_area_id: rating_area.id)
      enrollment2.update_attributes!(rating_area_id: rating_area.id)
      person.mailing_address.update_attributes(zip: "01001", county: "test", state: "AZ", kind: "mailing")
      modified_address = person.mailing_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
      @params = {
        address_set: {original_address: original_address,
                      modified_address: modified_address},
        change_set: {"old_set": {"state": "MT"},"new_set": {"state": "MA"}},
        person_hbx_id: person.hbx_id,
        primary_family_id: person.primary_family.id,
        is_primary: person.primary_family.present?
      }

      @result = subject.call(@params)
    end

    it "should return failure" do
      expect(@result).to be_failure
    end

    it "should return error message" do
      expect(@result.failure).to eq "RelocateEnrolledProducts: address_set should be of kind home"
    end
  end

  describe "when the system date is in December" do

    before :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 12, 1))
    end

    context "when the family only has enrollments in the current plan year" do
      before do
        allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
        allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
        BenefitMarkets::Locations::RatingArea.update_all(covered_states: nil)
        BenefitMarkets::Locations::RatingArea.where(:exchange_provided_code.nin => ["R-ME004"]).first.update_attributes(covered_states: nil, active_year: start_date.year, county_zip_ids: [county_zip.id], exchange_provided_code: "R-ME001")
        BenefitMarkets::Locations::ServiceArea.update_all(covered_states: ['ME'])
        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
        enrollment.update_attributes!(rating_area_id: rating_area.id)
        enrollment2.update_attributes!(rating_area_id: rating_area.id)
        person.home_address.update_attributes(zip: "04771", county: "Aroostook", state: "ME")
        modified_address = person.home_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
        @params = {
          address_set: {original_address: original_address,
                        modified_address: modified_address},
          change_set: {"old_set": {zip: county_zip.zip, county: county_zip.county_name},"new_set": {zip: "04771", county: "Aroostook"}},
          person_hbx_id: person.hbx_id,
          primary_family_id: person.primary_family.id,
          is_primary: person.primary_family.present?
        }
        @result = subject.call(@params)
      end

      it "should return failure" do
        expect(@result).to be_failure
      end

      it "should return error message" do
        expect(@result.failure).to eq "RelocateEnrolledProducts: No enrollments found for a given criteria"
      end
    end

    context "when the family has an enrollment in the current plan year and an enrollment in the prospective year" do
      let!(:enrollment_3) do
        FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, coverage_kind: "health", kind: "individual",
                                           aasm_state: "coverage_selected", effective_on: Date.new(TimeKeeper.date_of_record.next_year.year), :product => product)
      end

      before do
        allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
        allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
        BenefitMarkets::Locations::RatingArea.update_all(covered_states: nil)
        BenefitMarkets::Locations::RatingArea.where(:exchange_provided_code.nin => ["R-ME004"]).first.update_attributes(covered_states: nil, active_year: start_date.year, county_zip_ids: [county_zip.id], exchange_provided_code: "R-ME001")
        BenefitMarkets::Locations::ServiceArea.update_all(covered_states: ['ME'])

        rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(person.home_address)
        enrollment.update_attributes!(rating_area_id: rating_area.id)
        enrollment2.update_attributes!(rating_area_id: rating_area.id)
        enrollment_3.update_attributes!(rating_area_id: rating_area.id)
        person.home_address.update_attributes(zip: "04771", county: "Aroostook", state: "ME")
        modified_address = person.home_address.attributes.slice("address_1", "address_2", "address_3", "county", "kind", "city", "state", "zip").transform_keys(&:to_sym)
        @params = {
          address_set: {original_address: original_address,
                        modified_address: modified_address},
          change_set: {"old_set": {zip: county_zip.zip, county: county_zip.county_name},"new_set": {zip: "04771", county: "Aroostook"}},
          person_hbx_id: person.hbx_id,
          primary_family_id: person.primary_family.id,
          is_primary: person.primary_family.present?
        }
        @result = subject.call(@params)
      end
      it "should return success" do
        expect(@result).to be_success
      end
    end
  end
end