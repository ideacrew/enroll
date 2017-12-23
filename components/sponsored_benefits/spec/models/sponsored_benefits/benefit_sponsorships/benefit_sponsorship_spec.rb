require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do

    let(:initial_enrollment_period)             { Date.new(2018,5,1)..Date.new(2019,4,30) }
    let(:open_enrollment_period)                { Date.new(2018,4,1)..Date.new(2019,4,10) }
    let(:annual_enrollment_period_begin_month)  { initial_enrollment_period.min.month }
    let(:benefit_market)                        { :aca_shop_cca }
    let(:contact_method)                        { "Paper and Electronic communications" }

    let(:valid_params) do 
      {
        benefit_market: benefit_market,
        contact_method: contact_method,
        initial_enrollment_period: initial_enrollment_period,
        annual_enrollment_period_begin_month: annual_enrollment_period_begin_month,
      }
    end


    context "with an existing Organization Profile" do
      let(:cca_employer_profile)  { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new }
      let(:month_value_under)     { 0 }
      let(:month_value_over)      { 13 }

      subject {
          described_class.new(valid_params)
        }

      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "is not valid without a contact method" do
        subject.contact_method = nil
        expect(subject).to_not be_valid
      end

      it "is not valid without an initial enrollment period" do
        subject.initial_enrollment_period = nil
        expect(subject).to_not be_valid
      end

      it "is not valid without an annual enrollment period begin month" do
        subject.annual_enrollment_period_begin_month = nil
        expect(subject).to_not be_valid
      end

      it "is not valid without an out-of-range annual enrollment period begin month" do
        subject.annual_enrollment_period_begin_month = month_value_under
        subject.validate
        expect(subject.errors[:annual_enrollment_period_begin_month].first).to match /is not included in the list/

        subject.annual_enrollment_period_begin_month = month_value_over
        subject.validate
        expect(subject.errors[:annual_enrollment_period_begin_month].first).to match /is not included in the list/
      end

   end


  end
end
