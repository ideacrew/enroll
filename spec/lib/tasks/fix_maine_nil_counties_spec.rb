# frozen_string_literal: true

require 'rails_helper'
Rake.application.rake_require "tasks/fix_maine_nil_counties"
Rake::Task.define_task(:environment)

RSpec.describe 'migrations:fix_maine_nil_counties', :type => :task, dbclean: :after_each do
  # Main app stuff
  # HBX ID from the CSV
  let(:maine_zip) { '04401' }
  let(:maine_city) { 'Bangor' }
  let(:person) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "12345")}
  let(:person2) {FactoryBot.create(:person, :with_consumer_role, hbx_id: "123456")}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:dependent_family_member) do
    family.family_members.create(is_primary_applicant: false, is_consent_applicant: false, person: dependent_person)
  end
  let(:family_id) { family.id.to_s }
  let(:household) {FactoryBot.create(:household, family: family)}
  let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: TimeKeeper.date_of_record.beginning_of_year, effective_ending_on: nil, is_eligibility_determined: true)}
  let(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}
  # Financial Assistance Stuff
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft") }
  let!(:submitted_application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "submitted") }
  let!(:submitted_applicant) {FactoryBot.create(:financial_assistance_applicant, application: submitted_application, family_member_id: family.family_members.first.id)}
  let!(:eligibility_determination1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.first.id) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.last.id) }
  let!(:bad_county_address_person) do
    person = FactoryBot.create(:person, :with_consumer_role)
    person.addresses.each do |address|
      address.update_attributes!(county: BenefitMarkets::Locations::CountyZip.new, zip: maine_zip)
    end
  end
  let(:create_instate_addresses) do
    applicant1.addresses = [
        FactoryBot.build(
          :financial_assistance_address,
          :address_1 => '1111 Awesome Street NE',
          :address_2 => '#111',
          :address_3 => '',
          :city => maine_city,
          :country_name => '',
          :kind => 'home',
          :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
          :zip => maine_zip,
          county: BenefitMarkets::Locations::CountyZip.new
        )
    ]
    applicant1.save!
    application.save!
    # Dependents don't have county
    applicant2.addresses = [
      FactoryBot.build(
        :financial_assistance_address,
        :address_1 => '1111 Awesome Street NE',
        :address_2 => '#111',
        :address_3 => '',
        :city => EnrollRegistry[:enroll_app].setting(:contact_center_city).item,
        :country_name => '',
        :kind => 'home',
        :state => maine_city,
        :zip => maine_zip,
        county: ""
      )
    ]
    applicant2.save!
    application.save!
  end

  let(:submitted_instate_addresses) do
    submitted_applicant.addresses = [
        FactoryBot.build(
          :financial_assistance_address,
          :address_1 => '1111 Awesome Street NE',
          :address_2 => '#111',
          :address_3 => '',
          :city => maine_city,
          :country_name => '',
          :kind => 'home',
          :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
          :zip => maine_zip,
          county: BenefitMarkets::Locations::CountyZip.new
        )
    ]
    submitted_applicant.save!
    submitted_application.save!
  end

  context "Rake task" do
    before do
      person.addresses.first.update_attributes!(zip: maine_zip, county: "Zip code outside supported area")
      person2.addresses.first.update_attributes!(zip: maine_zip, county: "Monterey County")
      #applicant1.addresses.first.update_attributes(county: "Monterey County")
      ::BenefitMarkets::Locations::CountyZip.create!(
        county_name: "Hampden",
        zip: maine_zip,
        state: maine_city
      )
      person.person_relationships << PersonRelationship.new(relative: person, kind: "self")
      person.person_relationships.build(relative: dependent_person, kind: "spouse")
      person.consumer_role.ridp_documents.first.update_attributes(uploaded_at: TimeKeeper.date_of_record)
      person.save!
      family.save!
      create_instate_addresses
      submitted_instate_addresses
      expect(applicant2.addresses.first.county.blank?).to eq(true)
      county_people = Person.where("addresses.county" => /.*benefitmarkets.*/i)
      expect(county_people.present?).to eq(true)
      Rake::Task["migrations:fix_maine_nil_counties"].invoke
    end

    it "update the applicants with nil county values" do
      [applicant1, applicant2].each do |applicant|
        applicant.reload
        expect(applicant.addresses.to_a.select { |address| address.county.blank? }).to eq([])
      end
      county_people = Person.where("addresses.county" => /.*benefitmarkets.*/i)
      expect(county_people.present?).to eq(false)
    end

    it "update the applicants with zip code outside supported area" do
      person.reload
      blank_county = Person.where("addresses.county" => "Zip code outside supported area")
      expect(blank_county.count).to eq(0)
    end

    it "corrects county with word 'county' in county name" do
      person2.reload
      extra_county_name = Person.where("addresses.county" => "Monterey County")
      expect(extra_county_name.count).to eq(0)
    end

    it "updates the applicants with nil county values in submitted applications" do
      submitted_applicant.reload
      submitted_county_people = Person.where("addresses.county" => /.*benefitmarkets.*/i)
      expect(submitted_county_people.present?).to eq(false)
    end
  end
end