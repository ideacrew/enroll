# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::CensusEmployees::CopyRoster, :type => :model, dbclean: :after_each do
  context 'Failure' do
    context 'missing existing profile id' do
      it 'should return a failure with a message' do
        result = subject.call({ new_profile_id: BSON::ObjectId.new, new_benefit_sponsorship_id: BSON::ObjectId.new })
        expect(result.failure).to eq('Missing Existing Profile')
      end
    end

    context 'missing new profile id' do
      it 'should return a failure with a message' do
        result = subject.call({ existing_profile_id: BSON::ObjectId.new, new_benefit_sponsorship_id: BSON::ObjectId.new })
        expect(result.failure).to eq('Missing New Profile')
      end
    end

    context 'missing new benefit sponsorship id' do
      it 'should return a failure with a message' do
        result = subject.call({ existing_profile_id: BSON::ObjectId.new, new_profile_id: BSON::ObjectId.new })
        expect(result.failure).to eq('Missing New BenefitSponsorship')
      end
    end
  end

  context 'Success' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:sponsorship) { benefit_sponsorship }
    let(:new_benefit_sponsorship) do
      benefit_sponsorship = abc_profile.add_benefit_sponsorship
      benefit_sponsorship.aasm_state = benefit_sponsorship_state
      benefit_sponsorship.save

      benefit_sponsorship
    end
    let(:new_profile_id) { BSON::ObjectId.new }
    let!(:census_employees) { create_list(:census_employee, 5, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }

    it 'should copy roster' do
      expect(new_benefit_sponsorship.census_employees.size).to eq(0)
      subject.call({existing_profile_id: benefit_sponsorship.profile.id, new_profile_id: new_profile_id, new_benefit_sponsorship_id: new_benefit_sponsorship.id})
      expect(new_benefit_sponsorship.census_employees.size).to eq(5)
    end
  end
end
