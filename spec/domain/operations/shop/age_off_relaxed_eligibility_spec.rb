# frozen_string_literal: true

require "rails_helper"

module Operations
  RSpec.describe AgeOffRelaxedEligibility do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}

    subject do
      described_class.new.call(coverage_start: coverage_start, person: person, market_key: :aca_individual_dependent_age_off, relationship_kind: relationship_kind)
    end

    describe 'passing coverage_start, :person, :market_key, :relationship_kind' do

      context 'when dependent is 26 in that coverage year' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1993,9,1)) }
        let(:relationship_kind) { 'child' }

        it "should pass" do
          expect(subject).to be_success
        end
      end

      context 'when dependent above 26 in that coverage year' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1992,9,1)) }
        let(:relationship_kind) { 'child' }

        it "should fail" do
          expect(subject).not_to be_success
        end
      end

      context 'when dependent has a invalid relationship ' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1992,9,1)) }
        let(:relationship_kind) { 'parent' }

        it "should fail" do
          expect(subject).not_to be_success
        end
      end

      context 'when dependent has a valid relationship and is 26 in coverage year' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1993,9,1)) }
        let(:relationship_kind) { 'ward' }

        it "should pass" do
          expect(subject).to be_success
        end
      end

      context 'when dependent has a valid relationship and is under 26 in coverage year' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1994,9,1)) }
        let(:relationship_kind) { 'ward' }

        it "should pass" do
          expect(subject).to be_success
        end
      end

      context 'when dependent has a valid relationship and turns 26 on coverage start' do
        let(:coverage_start) { Date.new(2020, 1, 1) }
        let(:person) { FactoryBot.create(:person, :dob => Date.new(1994,1,1)) }
        let(:relationship_kind) { 'ward' }

        it "should pass" do
          expect(subject).to be_success
        end
      end
    end
  end
end