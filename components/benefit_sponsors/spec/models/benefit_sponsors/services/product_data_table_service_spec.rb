# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::ProductDataTableService, type: :model, :dbclean => :after_each do
    let(:product) { create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }

    describe "#retrieve_table_data" do
      it "should return exempt organization" do
        service_object = ::BenefitSponsors::Services::ProductDataTableService.new({ issuer_profile_id: product.issuer_profile_id })
        expect(service_object.retrieve_table_data).to eq [product]
      end
    end
  end
end
