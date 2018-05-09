require 'rails_helper'

describe "CarrierProfilesMigration" do

  before :all do
    Dir[Rails.root.join('db', 'migrate', '*_carrier_profiles_migration.rb')].each do |f|
      @test = f
      require f
    end
  end

  describe ".up" do

    before :all do
      site = FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, site_key: :dc)
      organization = FactoryGirl.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")
      broker_agency_profile = FactoryGirl.create(:broker_agency_profile, organization: organization)
      organization1 = FactoryGirl.create(:organization, legal_name: "Delta Dental")
      carrier_profile = FactoryGirl.create(:carrier_profile, organization: organization1)
      @employer_profile = FactoryGirl.create(:employer_profile)
      inbox = FactoryGirl.create(:inbox, :with_message, recipient: @employer_profile)
      employer_staff_role = FactoryGirl.create(:employer_staff_role, employer_profile_id: @employer_profile.id, benefit_sponsor_employer_profile_id: "123456")
      employee_role = FactoryGirl.create(:employee_role, employer_profile: @employer_profile)

      @migrated_organizations = BenefitSponsors::Organizations::Organization.issuer_profiles
      @old_organizations = Organization.exists(carrier_profile: true)


      @migrations_paths = Rails.root.join("db/migrate")
      @test_version = @test.split("/").last.split("_").first
    end

    it "should match total migrated organizations with carrier profiles" do
      Mongoid::Migrator.run(:up, @migrations_paths, @test_version.to_i)
      expect(@migrated_organizations.count).to eq @old_organizations.count
    end

    it "should not migrate organizations with broker agency profile" do
      expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.count).to eq 0
    end

    it "should match FEIN" do
      expect(@migrated_organizations.first.issuer_profile.issuer_hios_ids.first).to eq @old_organizations.first.carrier_profile.issuer_hios_id
    end

    it "should match office locations" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.count).to eq @old_organizations.first.office_locations.count
    end

    it "should match address" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.first.address.zip).to eq @old_organizations.first.office_locations.first.address.zip
    end

    it "should match phone" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.first.phone.full_phone_number).to eq @old_organizations.first.office_locations.first.phone.full_phone_number
    end
  end
end

