# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "insured/families/_insurance_fields.html.erb" do

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:default_is_your_health_coverage_ending_no).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:is_your_health_coverage_ending_expanded_question).and_call_original
    render partial: "insured/families/insurance_fields"
  end

  it "should select yes by default" do
    expect(rendered).to have_selector('input#reason_accept[checked=checked]')
  end

  it "should display the is_your_health_coverage_ending text" do
    text = l10n("insured.is_your_health_coverage_ending")
    expect(rendered).to include(text)
  end

  context 'is_your_health_coverage_ending_expanded flag enabled for insurance_fields partial' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:default_is_your_health_coverage_ending_no).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:is_your_health_coverage_ending_expanded_question).and_return(true)
      render partial: "insured/families/insurance_fields"
    end

    it "should display the is_your_health_coverage_ending_expanded text" do
      translation_keys = {
        contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item,
        contact_center_tty_number: EnrollRegistry[:enroll_app].settings(:contact_center_tty_number).item,
        contact_center_name: EnrollRegistry[:enroll_app].settings(:contact_center_name).item
      }
      text = l10n("insured.is_your_health_coverage_ending_expanded", translation_keys)
      expect(rendered).to include(text)
    end
  end

  context 'default_is_your_health_coverage_ending_no flag enabled for insurance_fields partial' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:default_is_your_health_coverage_ending_no).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:is_your_health_coverage_ending_expanded_question).and_call_original
      render partial: "insured/families/insurance_fields"
    end

    it "should select no by default" do
      expect(rendered).to have_selector('input#reason_accept1[checked=checked]')
    end
  end
end