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

    context "should update benefit sponsorship, when sponsorship has active benefit application" do

      let(:aasm_state) { :active }
      let(:benefit_sponsorship_state) { :applicant }

      it "should update benefit sponsorship state from applicant to active state" do
        expect(benefit_sponsorship.aasm_state).to eq :applicant
        subject.migrate
        benefit_sponsorship.reload
        expect(benefit_sponsorship.aasm_state).to eq :active
      end

      it "should create workflow state transition applicant -> active state" do
        expect(benefit_sponsorship.workflow_state_transitions.where(from_state: :applicant, to_state: :active).count).to eq 0
        subject.migrate
        benefit_sponsorship.reload
        expect(benefit_sponsorship.workflow_state_transitions.where(from_state: :applicant, to_state: :active).count).to eq 1
      end
    end

    context "should not update benefit sponsorship, when sponsorship has no active benefit application" do

      let(:aasm_state) { :enrollment_eligible }
      let(:benefit_sponsorship_state) { :applicant }

      it "should not update benefit sponsorship" do
        expect(benefit_sponsorship.aasm_state).to eq :applicant
        subject.migrate
        benefit_sponsorship.reload
        expect(benefit_sponsorship.aasm_state).to eq :applicant
      end
    end

  end
end
