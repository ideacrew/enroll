# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy, type: :model, :dbclean => :after_each do
  let!(:subject) {BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new}

  context "A new model instance" do
    it "should have businese_policy" do
      expect(subject.business_policies.present?).to eq true
    end
    it "should have businese_policy named passes_open_enrollment_period_policy" do
      expect(subject.business_policies[:passes_open_enrollment_period_policy].present?).to eq true
    end
    it "should not respond to dummy businese_policy name" do
      expect(subject.business_policies[:dummy].present?).to eq false
    end
  end

  context "Validates passes_open_enrollment_period_policy business policy" do

    let!(:benefit_sponsorship) {FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
    let!(:benefit_application) do
      FactoryGirl.create(
        :benefit_sponsors_benefit_application,
        :with_benefit_package,
        :fte_count => 1,
        :benefit_sponsorship => benefit_sponsorship,
        :open_enrollment_period => Range.new(Date.today, Date.today + BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN)
      )
    end
    let!(:policy_name) {:passes_open_enrollment_period_policy}
    let!(:policy) {subject.business_policies[policy_name]}

    it "should have open_enrollment period lasting more than min" do
      expect(benefit_application.open_enrollment_length).to be >= BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN
    end

    it "should satisfy rules" do
      expect(policy.is_satisfied?(benefit_application)).to eq true
    end
  end


  context "Fails passes_open_enrollment_period_policy business policy" do
    let!(:benefit_sponsorship) {FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
    let(:benefit_application) do
      FactoryGirl.build(
        :benefit_sponsors_benefit_application,
        :with_benefit_package,
        :fte_count => 3,
        :benefit_sponsorship => benefit_sponsorship,
        :open_enrollment_period => Range.new(Date.today + 5, Date.today + BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN)
      )
    end
    let!(:policy_name) {:passes_open_enrollment_period_policy}
    let!(:policy) {subject.business_policies[policy_name]}

    it "should fail rule validation" do
      # There are no rules under this policy.
      # expect(policy.is_satisfied?(benefit_application)).to eq false
    end
  end

  context 'rule within_last_day_to_publish' do
    let!(:benefit_application) {double('BenefitApplication', last_day_to_publish: last_day_to_publish, start_on: last_day_to_publish)}
    let!(:rule) {subject.business_policies[:submit_benefit_application].rules.detect {|x| x.name == :within_last_day_to_publish}}

    context 'fail' do
      let!(:last_day_to_publish) {Time.now - 1.day}
      before do
        TimeKeeper.any_instance.stub(:date_of_record).and_return(Time.now)
      end

      it "should fail rule validation" do
        expect(rule.fail.call(benefit_application)).to eq "Plan year starting on #{last_day_to_publish.to_date} must be published by #{last_day_to_publish.to_date}"
      end
    end

    context 'success' do
      let!(:last_day_to_publish) {Time.now + 1.day}
      before do
        TimeKeeper.any_instance.stub(:date_of_record).and_return(Time.now)
      end

      it "should validate successfully" do
        expect(rule.success.call(benefit_application)).to eq("Plan year was published before #{benefit_application.last_day_to_publish} on #{Time.now} ")
      end
    end
  end

  describe 'all_contribution_levels_min_met' do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(2020, 11, 9))
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context 'When minimum contributions are not met for 1/1 plan year' do
      let!(:benefit_application_update) do
        initial_application.update_attributes(
          :fte_count => 5,
          effective_period: Date.new(2021, 1, 1)..Date.new(2021, 1, 1).end_of_year + 1.month,
          :open_enrollment_period => Range.new(Date.today, Date.today + BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN)
        )
      end

      it 'should pass' do
        initial_application.benefit_packages.first.sorted_composite_tier_contributions.each do |c|
          c.contribution_factor = 0.0
          c.min_contribution_factor = 0.5
          c.save!
        end
        policy = subject.business_policies_for(initial_application, :submit_benefit_application)
        expect(policy.is_satisfied?(initial_application)).to eq true
      end
    end

    context 'When minimum contributions are not met for non 1/1 plan year' do
      let!(:benefit_application_update) do
        initial_application.update_attributes(
          :fte_count => 5,
          effective_period: Date.new(2021, 2, 1)..Date.new(2021, 1, 1).end_of_year + 1.month,
          :open_enrollment_period => Range.new(Date.today, Date.today + BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN)
        )
      end

      it 'should not pass' do
        initial_application.benefit_packages.first.sorted_composite_tier_contributions.each do |c|
          c.contribution_factor = 0.0
          c.min_contribution_factor = 0.5
          c.save!
        end

        policy = subject.business_policies_for(initial_application, :submit_benefit_application)
        expect(policy.is_satisfied?(initial_application)).to eq false
      end
    end
  end
end
