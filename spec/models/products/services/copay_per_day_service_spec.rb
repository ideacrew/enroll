# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayPerDayService do
  let(:amount) { "$300.00" }
  let(:not_applicable) {"Not Applicable"}

  context "In Network Costs" do
    context "$[PARAM] Copay per Day/Not Applicable Coinsurance" do
      let(:service_visit) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: "#{amount} Copay per Day", co_insurance_in_network_tier_1: not_applicable)
      end

      it "should return translated result" do
        expect(Products::Services::CopayPerDayService.new(service_visit).in_network_process).to eq "#{amount} copay per day"
      end
    end
  end
end
