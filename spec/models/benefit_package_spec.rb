require 'rails_helper'

RSpec.describe BenefitPackage, :type => :model do
  context "effective_year" do
    let(:hbx_profile) { FactoryBot.build(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first}

    it "should equal to start_on of benefit_coverage_period" do
      expect(benefit_package.effective_year).to eq benefit_package.benefit_coverage_period.start_on.year
    end
  end
end
