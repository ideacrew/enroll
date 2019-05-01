# Spec for Migrating Broker Organizations
require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "migrate_brokers_as_exempt_organizations")

describe MigrateBrokersAsExemptOrganizations, dbclean: :after_each do
  let(:given_task_name)          { "migrate_brokers_as_exempt_organizations" }
  let!(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:broker_general_organizations)    { FactoryGirl.create_list(:benefit_sponsors_organizations_general_organization, 4, :with_broker_agency_profile, site: site) }
  subject                        { MigrateBrokersAsExemptOrganizations.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "successful migration", dbclean: :after_each do
    it "should migrate all the general organizations" do
      expect(::BenefitSponsors::Organizations::ExemptOrganization.all.broker_agency_profiles.count).to eq 0
      expect(::BenefitSponsors::Organizations::GeneralOrganization.all.broker_agency_profiles.count).to eq 4
      subject.migrate
      expect(::BenefitSponsors::Organizations::ExemptOrganization.all.broker_agency_profiles.count).to eq 4
      expect(::BenefitSponsors::Organizations::GeneralOrganization.all.broker_agency_profiles.count).to eq 0
    end

    it "should not remove any associations after migration" do
      office_location_id = ::BenefitSponsors::Organizations::GeneralOrganization.all.broker_agency_profiles[0].broker_agency_profile.office_locations.first.id
      subject.migrate
      expect(::BenefitSponsors::Organizations::ExemptOrganization.all.broker_agency_profiles[0].broker_agency_profile.office_locations.first.id).to eq office_location_id
    end
  end

  describe "failed to migrate", dbclean: :after_each do
    let!(:dual_organization)    { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, :with_aca_shop_cca_employer_profile, site: site) }

    it "should not migrate the dual_organization as it has more than one profile" do
      subject.migrate
      expect(dual_organization.class).to eq BenefitSponsors::Organizations::GeneralOrganization
    end
  end

  after :each do
    FileUtils.rm_rf(Dir["#{Rails.root}/hbx_report"])
  end
end
