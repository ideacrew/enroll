# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_fehb_oe_dates_and_contribution_cap")

describe UpdateFehbOeDatesAndContributionCap, dbclean: :after_each do
  let(:given_task_name) { "update_fehb_oe_dates_and_contribution_cap" }
  let(:start_on)              { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_oe_start_on)   { TimeKeeper.date_of_record.beginning_of_month }
  let(:benefit_market)        { FactoryBot.create(:benefit_markets_benefit_market, :with_site, kind: :fehb) }
  let!(:organization)         { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_fehb_employer_profile, site: benefit_market.site) }
  let!(:employer_profile)     { organization.employer_profile }
  let!(:benefit_sponsorship)  { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) do
    FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_package,
                      :benefit_sponsorship => benefit_sponsorship,
                      :aasm_state => 'draft',
                      :open_enrollment_period => current_oe_start_on..(current_oe_start_on + 1.month),
                      :effective_period =>  start_on..(start_on + 1.year) - 1.day)
  end

  subject { UpdateFehbOeDatesAndContributionCap.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update_open_enrollment_dates" do
    let(:new_oe_start_on)       { (TimeKeeper.date_of_record + 1.month).beginning_of_month }
    let(:new_oe_end_on)         { new_oe_start_on + 10.days }

    it "should change open enrollment period" do
      ClimateControl.modify feins: organization.fein, effective_on: start_on.to_s, oe_start_on: new_oe_start_on.to_s, oe_end_on: new_oe_end_on.to_s, action: "update_open_enrollment_dates" do
        subject.migrate
        expect(benefit_application.reload.open_enrollment_period.min).to eq new_oe_start_on
        expect(benefit_application.reload.open_enrollment_period.max).to eq new_oe_end_on
      end
    end
  end

  describe "begin_open_enrollment" do
    it "should change effective on date" do
      ClimateControl.modify feins: organization.fein, effective_on: start_on.to_s, action: "begin_open_enrollment" do
        expect(benefit_application.aasm_state).to eq :draft
        subject.migrate
        expect(benefit_application.reload.aasm_state).to eq :enrollment_open
      end
    end
  end

  describe "update_contribution_cap" do
    let(:params_1)   { { order: "0", :is_offered => "true", :display_name => 'Employee Only', :contribution_factor => "95", contribution_unit_id: "5daa72db958c432288d715bb",   contribution_cap: 0.0 } }

    before do
      benefit_application.benefit_packages.first.sponsored_benefits.first.sponsor_contribution.contribution_levels = []
      benefit_application.benefit_packages.first.sponsored_benefits.first.sponsor_contribution.contribution_levels << BenefitSponsors::SponsoredBenefits::ContributionLevel.new(params_1)
    end

    it "should change contribution cap" do
      ClimateControl.modify feins: organization.fein, effective_on: start_on.to_s, employee_only_cap: '510.84', employee_plus_one_cap: '1092.26', family_cap: '1184.02', action: "update_contribution_cap" do
        level = benefit_application.benefit_packages.first.sponsored_benefits.first.sponsor_contribution.contribution_levels.first
        expect(level.contribution_cap).to eq 0.0
        subject.migrate
        expect(level.reload.contribution_cap).to eq 510.84
      end
    end
  end
end
