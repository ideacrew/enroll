# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'glue_load_products' do
  after :all do
    year = TimeKeeper.date_of_record.year
    json_file_name = Rails.root.join("#{year}_plans.json")
    error_file_name = Rails.root.join("#{year}_plans_error.txt")
    File.delete(json_file_name) if File.exist?(json_file_name)
    File.delete(error_file_name) if File.exist?(error_file_name)
  end

  let(:year) { TimeKeeper.date_of_record.year }
  let(:json_file_name) { Rails.root.join("#{year}_plans.json") }
  let(:error_file_name) { Rails.root.join("#{year}_plans_error.txt") }
  let!(:shop_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
  let!(:ivl_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product) }

  before do
    Rails.application.load_tasks
    Rake::Task.define_task(:environment)
  end

  describe 'load_products' do
    it 'should write products to the output file' do
      invoke_rake
      expect(File.exist?(json_file_name)).to be_truthy
      expect(File.read(json_file_name)).to include(shop_product.hios_id)
      expect(File.read(json_file_name)).to include(ivl_product.hios_id)
    end

    # Testing specifically with the load method b/c that is what is used to load the data in Glue
    # rubocop:disable Security/JSONLoad
    it 'should write output that can be loaded as array of json' do
      file_contents = File.read(json_file_name)
      loaded_json = JSON.load(file_contents)
      expect(loaded_json).to be_truthy
      expect(loaded_json.is_a?(Array)).to be_truthy
    end
    # rubocop:enable Security/JSONLoad

  end
end

def invoke_rake
  Rake::Task["seed:load_products"].reenable
  Rake::Task["seed:load_products"].invoke(TimeKeeper.date_of_record.year)
end