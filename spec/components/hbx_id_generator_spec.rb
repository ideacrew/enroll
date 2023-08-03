require 'rails_helper'

RSpec.describe 'Unique ID Generators' do
  [HbxIdGenerator,
   FinancialAssistance::HbxIdGenerator,
   SponsoredBenefits::Organizations::HbxIdGenerator,
   BenefitSponsors::Organizations::HbxIdGenerator].each do |id_generator|

    it "generates a 15-digit unique ID for #{id_generator}" do
      id = id_generator.slug!.random_uuid
      expect(id).to be_a(Integer)
      expect(id.to_s.length).to eq(15)
    end
  end
end
