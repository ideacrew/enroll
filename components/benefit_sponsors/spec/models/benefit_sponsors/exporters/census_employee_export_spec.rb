# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Exporters::CensusEmployeeExport, :dbclean => :after_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'
  include_context 'setup employees with benefits'

  let!(:health_products) do
    create_list(:benefit_markets_products_health_products_health_product,
                5, :with_renewal_product, :with_issuer_profile,
                application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
                product_package_kinds: [:single_issuer, :metal_level, :single_product],
                assigned_site: site,
                service_area: service_area,
                renewal_service_area: renewal_service_area,
                metal_level_kind: :gold)
  end
  let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day - 2.month }
  let(:current_effective_date) {effective_period_start_on}
  let(:effective_period_end_on) {effective_period_start_on + 1.year - 1.day}
  let(:effective_period) {effective_period_start_on..effective_period_end_on}

  let(:census_dependents_attributes) do
    {:first_name => 'David', :middle_name => '', :last_name => 'Chan', :dob => '2002-12-01', gender: 'female' ,:employee_relationship => 'child_under_26', :ssn => 678453261}
  end

  let(:census_dependents_attributes2) do
    {:first_name => 'Lara', :middle_name => '', :last_name => 'Chan', :dob => '1979-12-01', gender: 'male', :employee_relationship => 'spouse', :ssn => 657482918}
  end

  before :each do
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(100.0)
    census_employees.first.census_dependents.new(census_dependents_attributes)
    census_employees.first.save!
    abc_profile.reload
  end

  subject {BenefitSponsors::Exporters::CensusEmployeeExport.new(abc_profile, {action: 'download'})}

  context 'append_dependent' do
    it 'should return array of columns' do
      dependent = census_employees.first.census_dependents.first
      expect(subject.append_dependent(dependent).class).to eq Array
      expect(subject.append_dependent(dependent).count).to eq 3
    end
  end

  context 'dependent_count' do
    it 'should return max dependents count in census employees' do
      expect(subject.dependent_count).to eq 1
    end
  end

  context 'total_premium' do
    it 'should return total health premium' do
      expect(subject.total_premium(census_employees.first)).to eq ['$500.00', nil]
    end
  end

  context 'to_csv' do
    it 'should return total health premium' do
      csv_string = subject.to_csv
      csv_table = CSV.parse(csv_string, :headers => true, :skip_lines => /^DC Health Link Employee Census Template/)
      expect(csv_table.count).to eq 5 #number of census employee rows without header
      expect(csv_table.headers.count).to eq 28 #header columns count, changes with change in number of dependents
    end
  end
end
