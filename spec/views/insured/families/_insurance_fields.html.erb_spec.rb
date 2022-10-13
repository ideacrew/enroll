# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "insured/families/_insurance_fields.html.erb" do

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:default_is_your_health_coverage_ending_no).and_call_original
    render partial: "insured/families/insurance_fields"
  end

  it "should select yes by default" do
    expect(rendered).to have_selector('input#reason_accept[checked=checked]')
  end

  context 'default_is_your_health_coverage_ending_no flag enabled for insurance_fields partial' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:default_is_your_health_coverage_ending_no).and_return(true)
      render partial: "insured/families/insurance_fields"
    end

    it "should select no by default" do
      expect(rendered).to have_selector('input#reason_accept1[checked=checked]')
    end
  end

end