# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::ZeroCopayService do
  let(:zero_dollar) { "$0.00" }

  context "zero copay and zero coinsurance" do
    let(:service_visit) do
      build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: zero_dollar)
    end

    it "should return translated result" do
      expect(Products::Services::ZeroCopayService.new(service_visit).process).to eq Products::Services::BaseService::NO_CHARGE
    end
  end

  context "zero copay and 100% coinsurance" do
    let(:service_visit) do
      build(:products_qhp_service_visit, copay_in_network_tier_1: zero_dollar, co_insurance_in_network_tier_1: "100%")
    end

    it "should return translated result" do
      expect(Products::Services::ZeroCopayService.new(service_visit).process).to eq "Not covered. You are responsible for the full cost"
    end
  end
end
