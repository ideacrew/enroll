# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::IssuerDataTableService, type: :model, :dbclean => :after_each do
    let(:site)            { build(:benefit_sponsors_site, :with_owner_exempt_organization, :dc) }
    let!(:issuer_profile) { create(:benefit_sponsors_organizations_issuer_profile, organization: site.owner_organization) }

    describe "#retrieve_table_data" do
      it "should return exempt organization" do
        service_object = ::BenefitSponsors::Services::IssuerDataTableService.new
        expect(service_object.retrieve_table_data).to eq [issuer_profile.organization]
      end
    end
  end
end
