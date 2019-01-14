require 'spec_helper'

RSpec.describe BenefitSponsors::ApplicationHelper, type: :helper, dbclean: :after_each do
  include BenefitSponsors::ApplicationHelper

  describe '.profile_unread_messages_count', dbclean: :after_each do
    let(:inbox) { double('inbox', unread_messages: [1], unread_messages_count: 2 )}
    let(:profile) { double('Profile', inbox: inbox)}

    context 'when profile is an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(true)
      end
      it { expect(profile_unread_messages_count(profile)).to eq(1) }
    end

    context 'when profile is not an instance of BenefitSponsors::Organizations::Profile then' do
      before do
        expect(profile).to receive(:is_a?).and_return(false)
      end
      it { expect(profile_unread_messages_count(profile)).to eq(2) }
    end

    context 'when there is an error then', dbclean: :after_each do
      let(:site) { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:broker_organization) { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site) }
      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, market_kind: 'shop', legal_name: 'Legal Name1') }

      it "has the correct number of unread messages" do
        expect(profile_unread_messages_count(broker_agency_profile)).to eq(0)
      end
    end
  end
end
