require 'rails_helper'

module BenefitSponsors
  RSpec.describe Services::BenefitApplicationService, type: :model, :dbclean => :after_each do

    describe "constructor" do
      let(:benefit_sponser_ship) { double("BenefitSponsorship", {
          :benefit_market => "BenefitMarket",
          :profile_id => "rspec-id",
          :organization => "Organization"
      })}
      let(:benefit_factory) { double("BenefitApplicationFactory", benefit_sponser_ship: benefit_sponser_ship) }

      it "should initialize service factory" do
        service_obj = Services::BenefitApplicationService.new(benefit_factory)
        expect(service_obj.benefit_application_factory).to eq benefit_factory
      end
    end

    describe ".store service" do

      let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }

      let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
      let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) do
        {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period,
        }
      end

      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application) }
      let!(:invalid_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new}
      let(:benefit_application)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }
      let!(:invalid_benefit_application) { BenefitSponsors::BenefitApplications::BenefitApplication.new }
      let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
      let(:benefit_market) {benefit_sponsorship.benefit_market}
      let!(:benefit_application_factory) { BenefitSponsors::BenefitApplications::BenefitApplicationFactory }

      context "has received valid attributes" do
        it "should save updated benefit application" do
          allow(benefit_application).to receive(:benefit_sponsorship).and_return(benefit_sponsorship)
          allow(benefit_market).to receive(:benefit_sponsor_catalog_for).with([],benefit_application.effective_period.begin).and_return(nil)
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(benefit_application_form, benefit_application)).to eq [true, benefit_application]
        end
      end

      context "has received invalid attributes" do
        it "should map the errors to benefit application" do
          allow(benefit_application_factory).to receive(:validate).with(invalid_benefit_application).and_return false
          expect(invalid_application_form.valid?).to be_falsy
          expect(invalid_benefit_application.valid?).to be_falsy
          expect(invalid_application_form.errors.count).to eq 4
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(invalid_application_form, invalid_benefit_application)).to eq [false, nil]
          expect(invalid_application_form.errors.count).to eq 6
        end
      end
    end


    describe ".load_form_params_from_resource" do
      # use factory for benefit application
      it"should assign attributes to benefit application" do


      end
    end

  end
end