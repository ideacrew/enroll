require 'rails_helper'

RSpec.describe BenefitPackage, :type => :model do
  context "effective_year" do
    let(:benefit_package) {FactoryGirl.build(:benefit_package)}

    it "should equal to start_on of benefit_coverage_period" do
      expect(benefit_package.effective_year).to eq benefit_package.benefit_coverage_period.start_on.year
    end
  end
end
