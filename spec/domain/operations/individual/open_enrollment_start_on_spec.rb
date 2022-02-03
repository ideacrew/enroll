# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::OpenEnrollmentStartOn do
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }

  before :each do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
  end

  subject do
    described_class.new.call(params)
  end

  describe "Not passing params to call the operation" do
    let(:params) { { } }

    it "fails with an error message" do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given input is not in date format"
    end
  end

  describe "passing correct params to call the operation" do
    let(:params) {{date: effective_on}}

    it "Passes" do
      expect(subject).to be_success
      expect(subject.success).to eq benefit_coverage_period.open_enrollment_start_on
    end
  end
end
