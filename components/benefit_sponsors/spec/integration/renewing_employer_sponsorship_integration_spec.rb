require "rails_helper"
require "fileutils"

RSpec.describe "an MA ACA Employer" do

  def reload_db_fixtures
    db_name = Mongoid::Config.clients[:default][:database]
    db_location = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixture_dbs", "dump"))
    tmp_dir = Dir.mktmpdir
    dest_dir = File.join(tmp_dir, "dump")
    db_dump_src_dir = File.join(dest_dir, "fixture_source")
    db_dump_dest_dir = File.join(dest_dir, db_name)
    FileUtils.mkdir(dest_dir)
    FileUtils.cp_r(db_location, tmp_dir)
    FileUtils.mv(db_dump_src_dir, db_dump_dest_dir)
    `cd #{tmp_dir} && mongorestore --drop`
    FileUtils.rm_r(tmp_dir)
  end

  def primary_address_attributes
    {
      address_1: "27 Reo Road",
      state: "MA",
      zip: "01754",
      county: "Middlesex",
      city: "Maynard",
      kind: "work"
    }
  end

  def create_employer_organization
    primary_office_location = ::BenefitSponsors::Locations::OfficeLocation.new({
      :address => ::BenefitSponsors::Locations::Address.new(primary_address_attributes),
      :phone => BenefitSponsors::Locations::Phone.new({:area_code => "555", :number => "5555555", :kind => "phone main"}),
      is_primary: true
    })
    employer_profile = ::BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new({
      :sic_code => "2035",
      :contact_method => :paper_and_electronic,
      :office_locations => [primary_office_location]
    })
    employer_organization = ::BenefitSponsors::Organizations::GeneralOrganization.create!({
      :legal_name => "Generic Employer",
      :fein => "123423444",
      :entity_kind => "c_corporation",
      :profiles => [employer_profile],
      :site => ::BenefitSponsors::Site.first
    })
    employer_organization.profiles.first
  end

  describe "with a 2017 benefit sponsorship", dbclean: :after_all do

    before :all do
      reload_db_fixtures
      employer_profile = create_employer_organization
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
      @benefit_sponsorship = benefit_sponsorship
    end

    after :all do
      DatabaseCleaner.clean
    end

    it "should have a recorded rating area of R-MA003 from 2018" do
      rating_area = @benefit_sponsorship.rating_area
      expect(rating_area.exchange_provided_code).to eq("R-MA003")
      expect(rating_area.active_year).to eq(2018)
    end

    it "should be in 9 of service areas" do
      service_areas = @benefit_sponsorship.service_areas
      expect(service_areas.count).to eq(9)
    end
  end

  describe "with an initial 2017 benefit application", dbclean: :after_all do
    before :all do
      reload_db_fixtures
      employer_profile = create_employer_organization
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
			benefit_application = ::BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
				benefit_sponsorship,
				effective_period: (Date.new(2017,12,1)..Date.new(2018,11,30)),
				open_enrollment_period: (Date.new(2017,1,1)..Date.new(2017,11,15)),
				fte_count: 5,
				pte_count: 0,
				msp_count: 0
			)
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, benefit_application.effective_period.begin)
      benefit_application.save!
      @benefit_application = benefit_application
		end

    after :all do
      DatabaseCleaner.clean
    end

		it "should have a recorded rating area of R-MA003 from 2017" do
			rating_area = @benefit_application.recorded_rating_area
      expect(rating_area.exchange_provided_code).to eq("R-MA003")
      expect(rating_area.active_year).to eq(2017)
		end

		it "should be in 9 recorded service areas, from 2017" do
      service_areas = @benefit_application.recorded_service_areas
      expect(service_areas.count).to eq(11)
      service_area_years = service_areas.map(&:active_year).uniq
      expect(service_area_years).to eq([2017])
    end

		describe "and the resulting benefit_sponsor_catalog" do
      before :each do 
        @benefit_sponsor_catalog = @benefit_application.benefit_sponsor_catalog
      end

			it "should have the correct service areas" do
        service_area_ids = @benefit_application.recorded_service_area_ids.sort
        catalog_service_area_ids = @benefit_sponsor_catalog.service_area_ids.sort
        expect(service_area_ids).to eq(catalog_service_area_ids)
      end
		end
	end
end
