# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe Factories::EnrollmentRenewalFactory, type: :model, :dbclean => :after_each do

    let(:enrollment) do
      double("enrollment",
             benefit_group_assignment: benefit_group_assignment,
             is_coverage_waived?: true,
             coverage_kind: "health",
             product: product)
    end

    let(:product) do
      double("Product",
             renewal_product: double("RenewalProduct"))
    end

    let(:benefit_group_assignment) do
      double("benefit_group_assignment",
             census_employee: census_employee)
    end

    let(:census_employee) { instance_double("census_employee") }
    let(:sponsored_benefit) { instance_double("sponsored_benefit") }

    let(:benefit_package) do
      instance_double("benefit_package",
                      start_on: TimeKeeper.date_of_record)
    end

    context "#product not offered in renewal application" do
      before(:each) do
        allow(census_employee).to receive(:benefit_package_assignment_for).with(benefit_package).and_return(benefit_group_assignment)
        allow(benefit_package).to receive(:sponsored_benefit_for).with(enrollment.coverage_kind).and_return(sponsored_benefit)
        allow(sponsored_benefit).to receive(:products).with(benefit_package.start_on).and_return([product])
      end

      it "should raise error" do
        expect{BenefitSponsors::Factories::EnrollmentRenewalFactory.new(enrollment, benefit_package)}.to raise_error(RuntimeError, "Product not offered in renewal application")
      end
    end

  end
end
