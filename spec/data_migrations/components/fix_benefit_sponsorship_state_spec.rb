require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "components", "fix_benefit_sponsorship_state")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe FixBenefitSponsorshipState, dbclean: :after_each do
  let(:given_task_name) { "fix_benefit_sponsorship_state" }
  subject { FixBenefitSponsorshipState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employer benefit sponsorship aasm state" do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
        let(:effective_on) { current_effective_date }
        let(:aasm_state) { :active }
        let(:benefit_sponsorship_state) { :applicant }

    let(:employer_organization)   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }
    let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:employer_attestation)   { FactoryGirl.build(:employer_attestation, aasm_state:'unsubmitted') }
    let!(:benefit_sponsorship)   { employer_profile.add_benefit_sponsorship }


    it "should update benefit sponsorship state from applicant to active state" do
      expect(benefit_sponsorship.aasm_state).to eq :applicant
      subject.migrate
      benefit_sponsorship.reload
      expect(benefit_sponsorship.aasm_state).to eq :active
    end


  end
end
