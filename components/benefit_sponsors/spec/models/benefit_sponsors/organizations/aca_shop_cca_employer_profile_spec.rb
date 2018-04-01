require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::AcaShopCcaEmployerProfile, type: :model do

    let(:hbx_id)            { "56789" }
    let(:legal_name)        { "Tyrell Corporation" }
    let(:dba)               { "Offworld Enterprises" }
    let(:fein)              { "100001001" }
    let(:entity_kind)       { :s_corporation }

    let(:site)              { BenefitSponsors::Site.new(site_key: :cca) }
    let(:organization)      { BenefitSponsors::Organizations::GeneralOrganization.new(
                                  site: site, 
                                  hbx_id: hbx_id, 
                                  legal_name: legal_name, 
                                  dba: dba, 
                                  fein: fein, 
                                  entity_kind: entity_kind,
                                )}

    let(:address)           { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    let(:phone  )           { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location)   { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let(:office_locations)  { [office_location] }

    let(:sic_code)          { '1111' }
    let(:rating_area)       { BenefitSponsors::Locations::RatingArea.new }


    let(:params) do 
      {
        organization: organization,
        office_locations: office_locations,
        sic_code: sic_code,
        rating_area: rating_area,
      }
    end

    context "A new model instance" do

      context "with no sic_code" do
        subject { described_class.new(params.except(:sic_code)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no rating_area" do
        subject { described_class.new(params.except(:rating_area)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end



    context "Embedded in a Plan Design Proposal" do
      let(:title)                     { 'New proposal' }
      let(:cca_employer_profile)      { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(sic_code: sic_code) }

      let(:plan_design_organization)  { Organizations::PlanDesignOrganization.new(fein: fein, legal_name: legal_name, sic_code: sic_code) }
      let(:plan_design_proposal)      { plan_design_organization.plan_design_proposals.build(title: title, profile: cca_employer_profile) }
      let(:profile)                   { plan_design_organization.plan_design_proposals.first.profile }

      it "should save without error"
      it "should be findable"

    end

  end
end
