# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'set_minimum_contribution_factor_on_contribution_level')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe SetMinimumContributionFactorOnContributionLevel, dbclean: :after_each do

  let(:given_task_name) { "set_minimum_contribution_factor_on_contribution_level" }
  subject { SetMinimumContributionFactorOnContributionLevel.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { TimeKeeper.date_of_record }

    let(:health_sponsor_contribution) { initial_application.benefit_packages.first.health_sponsored_benefit.sponsor_contribution }

    it 'should have minimum contribution factor set on contribution levels' do
      expect(health_sponsor_contribution.contribution_levels.map(&:min_contribution_factor).sort).to eq [0.0, 0.0, 0.0, 0.0]
      subject.migrate
      initial_application.reload
      health_sponsor_contribution.reload
      expect(health_sponsor_contribution.contribution_levels.map(&:min_contribution_factor).sort).to eq [0.33, 0.33, 0.33, 0.5]
    end
  end
end

