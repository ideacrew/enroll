# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitMarkets::Locations::CountyFips, "with index definitions" do
  it "creates correct indexes" do
    BenefitMarkets::Locations::CountyFips.remove_indexes
    BenefitMarkets::Locations::CountyFips.create_indexes
  end
end