require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::BenefitApplicationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Forms::BenefitApplicationForm.new }

    describe "model attributes" do
      it {
        [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |key|
          expect(subject.attributes.has_key?(key)).to be_truthy
        end
      }
    end

    describe "validate Factory" do
      let(:build_benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application)}

      it "should be valid" do
        expect(build_benefit_application_form.valid?).to be_truthy
      end
    end

    describe "#for_new" do
      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application)}

      it "should assign benefit sponsorship" do
        form = BenefitSponsors::Forms::BenefitApplicationForm.for_new("rspec-id")
        expect(form.service).to be_instance_of(BenefitSponsors::Services::BenefitApplicationService)
        expect(form.start_on_options).not_to be nil
        expect(form.benefit_sponsorship_id).to eq "rspec-id"
      end
    end

    describe "#for_create" do
      let(:params) {
        {
          :start_on => (TimeKeeper.date_of_record.beginning_of_month + 2.months).strftime("%m/%d/%Y"),
          :end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.year + 2.months - 1.day).strftime("%m/%d/%Y"),
          :open_enrollment_start_on => (TimeKeeper.date_of_record.beginning_of_month).strftime("%m/%d/%Y"),
          :open_enrollment_end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.month + Settings.aca.shop_market.open_enrollment.monthly_end_on.days).strftime("%m/%d/%Y")
        }
      }

      it "should create the form assign the params for forms" do
        form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(params)
        expect(form.start_on).to eq params[:start_on]
        expect(form.open_enrollment_end_on).to eq params[:open_enrollment_end_on]
        expect(form.start_on_options).not_to be nil
      end
    end

    # describe ".publish" do
    #   let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
    #   let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_applications, benefit_sponsorship:benefit_sponsorship.id) }
    #   let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(id: benefit_application.id) }
    #   context "has to publish and" do
    #     it "should check service application warnings if any" do
    #
    #     end
    #   end
    # end



  end

end