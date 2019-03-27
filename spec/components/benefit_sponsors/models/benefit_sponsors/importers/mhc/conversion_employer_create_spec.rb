require "rails_helper"
module BenefitSponsors

  describe Importers::Mhc::ConversionEmployerCreate, dbclean: :after_each do

    before :all do
      DatabaseCleaner.clean
    end

    let!(:record_attrs) {
      {:action => "Add",
       :fein => "512121312",
       :dba => "Acme Contractors",
       :legal_name => "Acme, Inc.",
       :assigned_employer_id => "CGH10231",
       :sic_code => "1522",
       :primary_location_address_1 => "117 N Street NW",
       :primary_location_address_2 => "Suite 200",
       :primary_location_city => "Acushnet",
       :primary_location_county => "Bristol",
       :primary_location_county_fips => "025",
       :primary_location_state => "MA",
       :primary_location_zip => "2743",
       :mailing_location_address_1 => "P. O. Box 223344",
       :mailing_location_city => "Dartmouth",
       :mailing_location_state => "MA",
       :mailing_location_zip => "2108",
       :contact_first_name => "Roger",
       :contact_last_name => "Moore",
       :contact_email => "roger@liveandletdie.com",
       :contact_phone => "2025551212",
       :enrolled_employee_count => "1",
       :new_hire_count => "First of the month following 30 days",
       :mid_year_conversion => false
      }
    }

    let!(:registered_on) {TimeKeeper.date_of_record.beginning_of_month}
    let!(:site) {FactoryBot.create(:benefit_sponsors_site, :cca, :with_owner_exempt_organization)}
    let!(:benefit_market) {FactoryBot.create(:benefit_markets_benefit_market, site: site)}

    let!(:fein) {record_attrs[:fein]}
    let!(:carrier_profile) { FactoryBot.create(:carrier_profile, issuer_hios_ids: ['11111'], abbrev: 'BMCHP') }

    subject { BenefitSponsors::Importers::Mhc::ConversionEmployerCreate.new(record_attrs.merge({:registered_on => registered_on})) }



    context ".save" do

    before :each do
      @organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
    end

        it "should create employer profile as conversion" do
          expect(@organization).to be_blank
          subject.save
          employer_profile = BenefitSponsors::Organizations::Organization.where(fein: fein).first.employer_profile
          expect(employer_profile.present?).to be_truthy
          expect(employer_profile.sic_code).to eq record_attrs[:sic_code]
          expect(employer_profile.legal_name).to eq record_attrs[:legal_name]
          expect(employer_profile.dba).to eq record_attrs[:dba]
          sponsorship = employer_profile.organization.benefit_sponsorships.first
          expect(sponsorship.source_kind).to eq :conversion
          expect(sponsorship.employer_attestation.approved?).to be_truthy
        end

        it "should create employer profile as mid plan year conversion" do
          record_attrs[:mid_year_conversion] = true
          expect(@organization).to be_blank
          subject.save
          employer_profile = BenefitSponsors::Organizations::Organization.where(fein: fein).first.employer_profile
          expect(employer_profile.present?).to be_truthy
          expect(employer_profile.sic_code).to eq record_attrs[:sic_code]
          expect(employer_profile.legal_name).to eq record_attrs[:legal_name]
          expect(employer_profile.dba).to eq record_attrs[:dba]
          sponsorship = employer_profile.organization.benefit_sponsorships.first
          expect(sponsorship.source_kind).to eq :mid_plan_year_conversion
          expect(sponsorship.employer_attestation.approved?).to be_truthy
        end

        it "should create primary office location" do
          subject.save
          primary_location = BenefitSponsors::Organizations::Organization.where(fein: fein).first.employer_profile.primary_office_location.address
          expect(primary_location.address_1).to eq record_attrs[:primary_location_address_1]
          expect(primary_location.address_2).to eq record_attrs[:primary_location_address_2]
          expect(primary_location.city).to eq record_attrs[:primary_location_city]
          expect(primary_location.county).to eq record_attrs[:primary_location_county]
          expect(primary_location.location_state_code).to eq record_attrs[:primary_location_county_fips]
          expect(primary_location.state).to eq record_attrs[:primary_location_state]
          # we are pre-pending zeros to zip we are taking input from excel.
          expect(primary_location.zip).to eq ("0" << record_attrs[:primary_location_zip])
        end

        it "should create mailing location" do
          subject.save
          mailing_location = BenefitSponsors::Organizations::Organization.where(fein: fein).first.employer_profile.office_locations.detect {|o| o.is_primary == false}.address

          expect(mailing_location.address_1).to eq record_attrs[:mailing_location_address_1]
          expect(mailing_location.city).to eq record_attrs[:mailing_location_city]
          expect(mailing_location.state).to eq record_attrs[:mailing_location_state]
          # we are pre-pending zeros to zip we are taking input from excel.
          expect(mailing_location.zip).to eq("0" << record_attrs[:mailing_location_zip])
        end
    end
  end
end
