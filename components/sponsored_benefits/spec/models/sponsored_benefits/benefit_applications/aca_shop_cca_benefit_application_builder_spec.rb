require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::AcaShopCcaBenefitApplicationBuilder, type: :model, dbclean: :after_each do
    let(:start_of_next_month) { Date.today.next_month.beginning_of_month }
    let(:beginning_of_second_month) { start_of_next_month + 1.month }
    let(:valid_params) {
      {
        benefit_coverage_period: (beginning_of_second_month..(beginning_of_second_month + 1.year)),
        open_enrollment_period: (start_of_next_month..start_of_next_month.end_of_month),
        recorded_sic_code: "1234"
      }
    }

    let!(:subject) { BenefitApplications::AcaShopCcaBenefitApplicationBuilder.new(valid_params) }

    context "given the minimal params" do
      it "builds a basic application" do
        expect(subject.benefit_application).to be_kind_of(BenefitApplications::AcaShopCcaBenefitApplication)
      end
    end
  end
end
