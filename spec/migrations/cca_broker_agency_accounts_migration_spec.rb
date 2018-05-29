require 'rails_helper'

describe "CcaBrokerAgencyAccountsMigration" do

  before :all do
    DatabaseCleaner.clean

    Dir[Rails.root.join('db', 'migrate', '*_cca_broker_agency_accounts_migration.rb')].each do |f|
      @path = f
      require f
    end
  end

  describe ".up" do

    before :all do
      FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, site_key: :mhc)

      organization = FactoryGirl.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")
      FactoryGirl.create(:broker_agency_profile, organization: organization)

      organization1 = FactoryGirl.create(:organization, legal_name: "Delta Dental")
      FactoryGirl.create(:carrier_profile, organization: organization1)

      employer_profile = FactoryGirl.create(:employer_profile)
      document1 = FactoryGirl.build(:document)
      document2 = FactoryGirl.build(:document)
      employer_profile.organization.documents << document1
      employer_profile.documents << document2
      # employer_profile.organization.home_page = nil
      FactoryGirl.create(:inbox, :with_message, recipient: employer_profile)
      FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id, benefit_sponsor_employer_profile_id: "123456")
      FactoryGirl.create(:employee_role, employer_profile: employer_profile)
      FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)

      @migrated_organizations = BenefitSponsors::Organizations::Organization.employer_profiles
      @old_organizations = Organization.all_employer_profiles

      @migrations_paths = Rails.root.join("db/migrate")
      @test_version = @path.split("/").last.split("_").first
    end


    it "should match total migrated organizations" do
#TODO
    end

  end
  # after(:all) do
  #   FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report//employer_profiles_migration_*"])
  # end
end