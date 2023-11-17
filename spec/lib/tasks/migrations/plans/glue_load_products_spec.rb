# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'glue_load_products' do

  let(:year) { TimeKeeper.date_of_record.year }
  let(:json_file_name) { Rails.root.join("#{year}_plans.json") }
  let(:error_file_name) { Rails.root.join("#{year}_plans_error.txt") }
  let!(:shop_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
  let!(:ivl_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer_profile) }
  let!(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile, fein: '123456789') }

  before :all do
    DatabaseCleaner.clean
    Rake.application.rake_require 'tasks/migrations/plans/glue_load_products'
    Rake::Task.define_task(:environment)
  end

  after :all do
    year = TimeKeeper.date_of_record.year
    json_file_name = Rails.root.join("#{year}_plans.json")
    error_file_name = Rails.root.join("#{year}_plans_error.txt")
    File.delete(json_file_name) if File.file?(json_file_name)
    File.delete(error_file_name) if File.file?(error_file_name)
  end

  describe 'load_products' do
    it 'should write products to the output file' do
      invoke_rake
      expect(File.exist?(json_file_name)).to be_truthy
      expect(@file_contents).to include(shop_product.hios_id)
      expect(@file_contents).to include(ivl_product.hios_id)
    end

    it 'should write output that can be loaded as array of json' do
      invoke_rake
      expect(@loaded_json).to be_truthy
      expect(@loaded_json.is_a?(Array)).to be_truthy
    end
  end

  context 'when CarrierProfile does not return fein' do
    it 'should use the fein on the IssuerProfile' do
      invoke_rake
      ivl_plan = @loaded_json.detect {|p| p['hios_plan_id'] == ivl_product.hios_id}
      fein = ivl_product.issuer_profile.organization.fein
      expect(ivl_plan['fein']).to eq(fein)
    end
  end
end

def invoke_rake
  year = TimeKeeper.date_of_record.year
  json_file_name = Rails.root.join("#{year}_plans.json")
  error_file_name = Rails.root.join("#{year}_plans_error.txt")
  File.delete(json_file_name) if File.exist?(json_file_name)
  File.delete(error_file_name) if File.exist?(error_file_name)
  Rake::Task["seed:load_products"].reenable
  Rake::Task["seed:load_products"].invoke(year)
  @file_contents = File.read(json_file_name)
  # Testing specifically with the load method b/c that is what is used to load the data in Glue
  # rubocop:disable Security/JSONLoad
  @loaded_json = JSON.load(@file_contents)
  # rubocop:enable Security/JSONLoad
end