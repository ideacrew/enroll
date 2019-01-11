module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfile, type: :model do
    it {should validate_presence_of(:market_kind)}

    context "#find" do
      let(:general_agency) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }

      it "should find general agency profile" do
        profile_id = general_agency.profiles.first.id
        expect(subject.class.find(profile_id)).to eq general_agency.profiles.first
      end
    end
  end
end
