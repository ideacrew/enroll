require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do

    let(:benefit_market)                        { :aca_shop_cca }
    let(:enrollment_frequency)                  { :rolling_month }
    let(:contact_method)                        { "Paper and Electronic communications" }
    let(:initial_enrollment_period)             { Date.new(2018,5,1)..Date.new(2019,4,30) }
    let(:open_enrollment_period)                { Date.new(2018,4,1)..Date.new(2019,4,10) }
    let(:annual_enrollment_period_begin_month)  { initial_enrollment_period.min.month }

    let(:valid_params) do 
      {
        benefit_market: benefit_market,
        contact_method: contact_method,
        enrollment_frequency: enrollment_frequency,
        initial_enrollment_period: initial_enrollment_period,
        annual_enrollment_period_begin_month: annual_enrollment_period_begin_month,
      }
    end

    let(:month_value_under)             { 0 }
    let(:month_value_over)              { 13 }
    let(:invalid_enrollment_frequency)  { :weekly }

    subject {
        described_class.new(valid_params)
      }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a benefit market" do
      subject.benefit_market = nil
      expect(subject).to_not be_valid
    end

    it "is not valid without a enrollment frequency" do
      subject.enrollment_frequency = invalid_enrollment_frequency
      subject.validate
      expect(subject.errors[:enrollment_frequency].first).to match /weekly is not a valid enrollment frequency kind/
    end

    it "is not valid without a contact method" do
      subject.contact_method = nil
      expect(subject).to_not be_valid
    end

    it "is not valid with an invalid enrollment frequency" do
      subject.contact_method = nil
      expect(subject).to_not be_valid
    end

    it "is not valid with an out-of-range annual enrollment period begin month" do
      subject.annual_enrollment_period_begin_month = month_value_under
      subject.validate
      expect(subject.errors[:annual_enrollment_period_begin_month].first).to match /is not included in the list/

      subject.annual_enrollment_period_begin_month = month_value_over
      subject.validate
      expect(subject.errors[:annual_enrollment_period_begin_month].first).to match /is not included in the list/
    end

    context "as component of a Plan Design Organization" do
      let(:title)                     { 'New proposal' }
      let(:cca_employer_profile)      { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new }

      let(:plan_design_organization)  { Organizations::PlanDesignOrganization.new(fein: fein, legal_name: legal_name, sic_code: sic_code) }
      let(:plan_design_proposal)      { plan_design_organization.plan_design_proposals.build(title: title, profile: cca_employer_profile) }
      let(:profile)                   { plan_design_organization.plan_design_proposals.first.profile }

      before { plan_design_organization.save! }

      it "should not validate presence of initial enrollment period or annual enrollment period begin month"
      it "should allow updates to initial enrollment period"


    end

    context "as component of an Organization" do
      let(:fein)            { '42-6854567' }
      let(:legal_name)      { 'Acme Widgets, Inc.' }
      let(:sic_code)        { '1111' }
      let(:organization)    { ::Organization.new(fein: fein, legal_name: legal_name, sic_code: sic_code) }

      # it "is not valid without an initial enrollment period" do
      #   subject.initial_enrollment_period = nil
      #   expect(subject).to_not be_valid
      # end

      # it "is not valid without an annual enrollment period begin month" do
      #   subject.annual_enrollment_period_begin_month = nil
      #   expect(subject).to_not be_valid
      # end

    end
 
  end
end
