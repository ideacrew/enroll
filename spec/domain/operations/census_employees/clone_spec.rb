# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::CensusEmployees::Clone, :type => :model, dbclean: :after_each do

  let(:census_employee)      { FactoryBot.create(:census_employee) }

  context 'missing keys' do
    context 'missing census_employee' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing CensusEmployee.')
      end
    end
  end

  context 'invalid census employee' do
    before do
      @result = subject.call({census_employee: double("Census Employee"), additional_attrs: {}})
    end

    it 'should return a failure with a message' do
      expect(@result.failure).to eq('Not a valid CensusEmployee object.')
    end
  end

  context 'invalid additional_attrs' do
    before do
      @result = subject.call({census_employee: census_employee, additional_attrs: []})
    end

    it 'should return a failure with a message' do
      expect(@result.failure).to eq("Invalid options's value. Should be a Hash.")
    end
  end

  context 'Success' do
    before do
      @result = subject.call({census_employee: census_employee, additional_attrs: { benefit_sponsors_employer_profile_id: BSON::ObjectId.new, benefit_sponsorship_id: BSON::ObjectId.new }})
    end

    it 'should return a census_employee object' do
      expect(@result.success).to be_a(CensusEmployee)
    end

    it 'should return success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return true' do
      expect(@result.success).to be_truthy
    end
  end
end
