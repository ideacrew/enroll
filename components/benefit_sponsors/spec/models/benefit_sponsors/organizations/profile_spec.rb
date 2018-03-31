require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::Profile, type: :model do

    let(:hbx_id)            { "56789" }
    let(:legal_name)        { "Tyrell Corporation" }
    let(:dba)               { "Offworld Enterprises" }
    let(:fein)              { "100001001" }

    let(:site)              { BenefitSponsors::Site.new(site_key: :dc) }
    let(:organization)      { BenefitSponsors::Organizations::GeneralOrganization.new(
                                  site: site, 
                                  hbx_id: hbx_id, 
                                  legal_name: legal_name, 
                                  dba: dba, 
                                  fein: fein, 
                                )}

    let(:address)           { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    let(:phone  )           { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location)   { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }

    let(:office_locations)  { [office_location] }


    let(:params) do 
      {
        organization: organization,
        office_locations: office_locations,
      }
    end

    context "A new model instance" do
      context "with no organization" do
        subject { described_class.new(params.except(:organization)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no office_locations" do
        subject { described_class.new(params.except(:office_locations)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without a primary office location" do
        let(:invalid_address)         { BenefitSponsors::Locations::Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
        let(:invalid_office_location) { BenefitSponsors::Locations::OfficeLocation.new(is_primary: false, address: invalid_address, phone: phone) }

        subject { described_class.new(office_locations: [invalid_office_location] ) }

        it "should not be valid" 
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should default the is_benefit_sponsorship_eligible attribute to false" do
            expect(subject.is_benefit_sponsorship_eligible).to eq false
          end

          it "should access organization values for delegated attributes" do
            expect(subject.hbx_id).to eq hbx_id
            expect(subject.legal_name).to eq legal_name
            expect(subject.dba).to eq dba
            expect(subject.fein).to eq fein
          end

          context "and delegated attributes are changed in the profile model" do
            let(:changed_legal_name)    { "Wallace Corporation" }
            let(:changed_dba)           { "Offworld Adventures" }
            let(:changed_fein)          { "200002002" }

            before do 
              subject.legal_name  = changed_legal_name
              subject.dba         = changed_dba
              subject.fein        = changed_fein
            end

            it "should update organization values for delegated attributes" do
              expect(subject.organization.legal_name).to eq changed_legal_name
              expect(subject.organization.dba).to eq changed_dba
              expect(subject.organization.fein).to eq changed_fein
            end            
          end

        end
      end

    end






    # let(:is_benefit_sponsorship_eligible) { true }
    # let(:sponsorship_profile)             { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }
    # let(:benefit_market)                  { BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "DC Health SHOP", site: site) }
    # let(:contact_method_kind)             { :paper_and_electronic }



  end
end
