require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe Concerns::EmployerDatatableConcern, type: :model, dbclean: :after_each do
    describe "#benefit_application_initial_binder_paid" do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      before do
        initial_application.update_attributes!(aasm_state: :binder_paid)
      end

      context "when billing date is given" do
        it "should return all benefit sponsorships with binder paid benefit applications" do
          expect(BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_initial_binder_paid.to_a).to eq [benefit_sponsorship]
        end
      end
    end
  end
end