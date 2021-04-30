# frozen_string_literal: true

require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "golden_seed_update_benefit_application_dates")
require File.join(Rails.root, "app", "data_migrations", "golden_seed_shop")
require File.join(Rails.root, "app", "data_migrations", "golden_seed_individual")
require File.join(Rails.root, "components", "benefit_sponsors", "spec", "support", "benefit_sponsors_site_spec_helpers")
require File.join(Rails.root, "app", "data_migrations", "load_issuer_profiles")

describe "Golden Seed Rake Tasks", dbclean: :after_each do
  describe "Generate Consumers and Families for Individual Market" do
    let(:given_task_name) { "golden_seed_individual" }
    subject { GoldenSeedIndividual.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "requirements" do
      before :each do
        subject.migrate
      end

      it "will not create new hbx profile and benefit sponsorship if they are already present" do
        expect(HbxProfile.all.count).to eq(1)
        subject.migrate
        expect(HbxProfile.all.count).to eq(1)
        expect(HbxProfile.all.map(&:benefit_sponsorship).count).to eq(1)
      end

      it "should create at least one IVL health product if none exist" do
        products = BenefitMarkets::Products::Product.all.select { |product| product.benefit_market_kind.to_sym == :aca_individual }
        expect(products.count).to_not be(0)
      end

      it "should create fully matched consumer records" do
        consumer_roles = Person.all.select { |person| person.consumer_role.present? }
        expect(consumer_roles.count).to_not be(0)
      end

      it "should create active enrollments" do
        expect(HbxEnrollment.enrolled.count).to be > 1
      end
    end
  end

  describe "Generate Employers, Employees, and Dependents for SHOP" do
    let(:given_task_name) { "golden_seed_shop" }
    subject { GoldenSeedSHOP.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "requirements" do
      let(:test_employer) do
        BenefitSponsors::Organizations::Organization.where(legal_name: /Golden Seed/).first
      end
      let(:load_issuer_profiles_task_name) { "load_issuer_profiles" }
      let(:load_issuer_profiles_rake) { LoadIssuerProfiles.new(load_issuer_profiles_task_name, double(:current_scope => nil)) }

      #let!(:site) { FactoryBot.create(:benefit_sponsors_site, :as_hbx_profile, :cca) }
      let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
      let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
      let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
      let!(:service_area) { create_default(:benefit_markets_locations_service_area) }
      let!(:next_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year + 1) }
      let!(:next_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year + 1) }
      let!(:site) { ::BenefitSponsors::SiteSpecHelpers.create_cca_site_with_hbx_profile_and_benefit_market }
      let(:benefit_market)      { site.benefit_markets.first }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let!(:benefit_market_catalog) do
        create(:benefit_markets_benefit_market_catalog, :with_product_packages,
               benefit_market: benefit_market,
               title: "SHOP Benefits for #{current_effective_date.year}",
               application_period: (effective_period_start_on.beginning_of_year..effective_period_start_on.end_of_year))

      end
      let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }
      let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}


      before :each do
        system("bundle exec rake migrations:load_issuer_profiles")
        load_issuer_profiles_rake.migrate
        subject.migrate
      end

      xit "should create employers and employer profiles" do
        expect(test_employer.persisted?).to eq(true)
        expect(BenefitSponsors::Organizations::GeneralOrganization.all.count).to eq(27)
      end

      xit "should create employers with sic code" do
        expect(test_employer.employer_profile.sic_code).to eq("0111")
      end

      xit "should create an MA office location for employer profile" do
        expect(test_employer.employer_profile.office_locations.first.class).to eq(BenefitSponsors::Locations::OfficeLocation)
        expect(test_employer.employer_profile.office_locations.first.address.state).to eq("MA")
      end

      xit "should create census employees belonging to a specific employer/employee_role" do
        expect(test_employer.employer_profile.census_employees.count).to eq(26)
      end

      xit "should create families" do
        expect(Family.all.count).to eq(26)
      end

      xit "should create employee roles" do
        expect(EmployeeRole.first.class).to eq(EmployeeRole)
      end

      xit "should create person records with employee roles" do
        expect(Person.all.count).to eq(58)
      end

      xit "should create users" do
        expect(User.all.count).to eq(26)
      end

      # xit "should create dependents for a family" do
        # TODO: Do this
      # end

      # xit "should not modify existing plans" do

      # end

      describe "benefits" do
        xit "should create employers with benefit sponsorships" do
          expect(test_employer.benefit_sponsorships.last.class).to eq(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
        end

        describe "requirements" do
          xit "should create benefit packages" do
            benefit_application = test_employer.benefit_sponsorships.last.benefit_applications.last.reload
            benefit_package = benefit_application.benefit_packages.last
            expect(benefit_package.class).to eq(BenefitSponsors::BenefitPackages::BenefitPackage)
          end
        end

        xit "should create benefit applications for a given employer benefit package" do
          expect(test_employer.benefit_sponsorships.last.benefit_applications.count).to eq(1)
        end
      end
    end
  end

  describe "Update Benefit Application Dates" do
    # let(:date_range) { (Date.today..1.year.from_now) }

    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period
      }
    end

    let(:benefit_application)       { SponsoredBenefits::BenefitApplications::BenefitApplication.new(params) }
    let(:benefit_sponsorship)       do
      SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
        benefit_market: "aca_shop_cca",
        enrollment_frequency: "rolling_month"
      )
    end

    let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Boston", state: "MA", zip: "02109", county: "Suffolk") }
    let(:phone)  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location) do
      OfficeLocation.new(
        is_primary: true,
        address: address,
        phone: phone
      )
    end
    let(:benefit_group)             { FactoryBot.create :benefit_group, title: 'new' }

    let(:benefit_market)      { site.benefit_markets.first }
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let!(:benefit_market_catalog) do
      create(:benefit_markets_benefit_market_catalog, :with_product_packages,
             benefit_market: benefit_market,
             title: "SHOP Benefits for #{current_effective_date.year}",
             application_period: (effective_period_start_on.beginning_of_year..effective_period_start_on.end_of_year))

    end
    let!(:product)      { benefit_market_catalog.product_packages.where(package_kind: 'single_product').first.products.first}
    let!(:plan) {benefit_group.reference_plan}
    let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area, active_year: effective_period_start_on.year }
    let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: effective_period_start_on.year }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_sponsor_organization) do
      FactoryBot.create(
        :benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site, legal_name: 'Broadcasting llc'
      )
    end
    let(:sponsor_benefit_sponsorship) { benefit_sponsor_organization.employer_profile.add_benefit_sponsorship }

    let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "plan design xyz", office_locations: [office_location], sic_code: sic_code) }
    let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
    let(:sic_code) { "123345" }
    let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new(sic_code: sic_code) }

    before(:each) do
      plan.hios_id = product.hios_id
      plan.save
      sponsor_benefit_sponsorship.rating_area = rating_area
      sponsor_benefit_sponsorship.service_areas = [service_area]
      sponsor_benefit_sponsorship.save
      #general_org_benefit_app
      plan_design_organization.plan_design_proposals << [plan_design_proposal]
      plan_design_proposal.profile = profile
      profile.benefit_sponsorships = [benefit_sponsorship]
      benefit_sponsorship.benefit_applications = [benefit_application]
      benefit_application.benefit_groups << benefit_group
      plan_design_organization.save!
      benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.build(
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period
      )
      benefit_sponsor_organization.active_benefit_sponsorship.save!
      expect(BenefitSponsors::Organizations::Organization.all.count).to eq(2)
      expect(BenefitSponsors::Organizations::Organization.all.where(legal_name: "Broadcasting llc").first.present?).to eq(true)
      expect(BenefitSponsors::Organizations::Organization.all.where(legal_name: "Broadcasting llc").first.active_benefit_sponsorship.benefit_applications.present?).to eq(true)
    end

    let(:given_task_name) { "golden_seed_update_benefit_application_dates" }
    subject! { GoldenSeedUpdateBenefitApplicationDates.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      xit "has the given task name" do
        expect(subject.name).to eql given_task_name
      end

      describe "Passing specific employer legal names: instance variables" do
        xit "should target the specific legal name organization" do
          benefit_sponsor_organization.update_attributes!(legal_name: "Pizza Planet")
          ENV['coverage_start_on'] = "01/01/2021"
          ENV['coverage_end_on'] = "03/31/2021"
          ENV['target_employer_name_list'] = "Pizza Planet"
          subject.migrate
          expect(subject.get_target_organizations.last.legal_name).to eq("Pizza Planet")
        end
      end

      describe "Default database dump: instance variables" do
        before :each do
          ENV['coverage_start_on'] = "01/01/2021"
          ENV['coverage_end_on'] = "03/31/2021"
          ENV['target_employer_name_list'] = nil
          subject.migrate
        end

        xit "sets organization_collection as instance variable" do
          expect(subject.get_target_organizations.last.class.to_s).to eq('BenefitSponsors::Organizations::GeneralOrganization')
        end

        xit "sets benefit_sponsorships as instance variable" do
          expect(subject.get_benefit_sponsorships_of_organizations.last.class.to_s).to eq("BenefitSponsors::BenefitSponsorships::BenefitSponsorship")
        end
        xit "sets benefit_applications as instance variable" do
          expect(subject.get_benefit_applications_of_sponsorships.last.class.to_s).to eq("BenefitSponsors::BenefitApplications::BenefitApplication")
        end
      end
    end

    describe "updating benefit applications", dbclean: :after_each do
      before :each do
        ENV['coverage_start_on'] = "01/01/2020"
        ENV['coverage_end_on'] = "03/31/2020"
        ENV['target_employer_name_list'] = nil
        subject.migrate
      end

      describe "requirements" do
        xit "should modify benefit application coverage start_on" do
          expect(subject.get_benefit_applications_of_sponsorships.last.effective_period.min.to_date.to_s).to eq("01/01/2020")
        end

        xit "should modify benefit application coverage end_on" do
          expect(subject.get_benefit_applications_of_sponsorships.last.effective_period.max.to_date.to_s).to eq("03/31/2020")
        end

        xit "should modify benefit application open_enrollment_start_on" do
          expect(subject.get_benefit_applications_of_sponsorships.last.open_enrollment_start_on.to_date.to_s).to eq("11/01/2019")
        end

        xit "should modify benefit application open_enrollment_end_on" do
          expect(subject.get_benefit_applications_of_sponsorships.last.open_enrollment_end_on.to_date.to_s).to eq("12/20/2019")
        end

        # xit "should modify recalculate the appropriate prices" do

        # end
      end
    end
  end
end