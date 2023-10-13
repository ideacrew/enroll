# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitMarkets::Locations::CountyZip, "with index definitions" do
  it "creates correct indexes" do
    BenefitMarkets::Locations::CountyZip.remove_indexes
    BenefitMarkets::Locations::CountyZip.create_indexes
  end
end