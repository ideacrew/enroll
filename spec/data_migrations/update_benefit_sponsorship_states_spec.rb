# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, "app", "data_migrations", "update_benefit_sponsorship_states")

describe UpdateBenefitSponosorshipStates, dbclean: :after_each do

  let(:given_task_name) { "update_benefit_sponsorship_states" }
  subject { UpdateBenefitSponosorshipStates.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the benefit sponsorships and benefit applications", dbclean: :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    old_states = [:initial_application_under_review, :initial_application_denied, :initial_application_approved, :initial_enrollment_open, :initial_enrollment_closed, :initial_enrollment_ineligible, :initial_enrollment_eligible]

    old_states.each do |old_state|
      context "when benefit sponsorship is in any of the initial states" do

        before do
          benefit_sponsorship.update_attributes!(aasm_state: old_state)
        end

        it "should update benefit sponsorship state to applicant" do
          expect(benefit_sponsorship.aasm_state).to eq old_state
          subject.migrate
          expect(benefit_sponsorship.reload.aasm_state).to eq :applicant
        end
      end
    end

    valid_states = [:applicant, :active, :denied, :suspended, :terminated, :ineligible]

    valid_states.each do |valid_state|
      context "when benefit sponsorship is in any state other than initial state" do

        before do
          benefit_sponsorship.update_attributes!(aasm_state: valid_state)
        end

        it "should not update benefit sponsorship state" do
          expect(benefit_sponsorship.aasm_state).to eq valid_state
          subject.migrate
          expect(benefit_sponsorship.reload.aasm_state).to eq valid_state
        end
      end
    end

    context "when benefit applications with initial_enrollment_eligible state are present" do

      let(:benefit_application) { benefit_sponsorship.benefit_applications.first }

      before do
        benefit_sponsorship.update_attributes!(aasm_state: :initial_enrollment_eligible)
        benefit_application.update_attributes!(aasm_state: :enrollment_eligible)
      end

      it "should update benefit application to binder paid state" do
        expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_eligible
        expect(benefit_application.aasm_state).to eq :enrollment_eligible
        subject.migrate
        expect(benefit_sponsorship.reload.aasm_state).to eq :applicant
        expect(benefit_application.reload.aasm_state).to eq :binder_paid
      end
    end
  end
end
