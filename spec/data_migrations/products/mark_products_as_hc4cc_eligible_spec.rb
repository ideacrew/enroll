# frozen_string_literal: true

require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "products", "mark_products_as_hc4cc_eligible")

describe MarkProductsAsHc4ccEligible, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:given_task_name) { "mark_products_as_hc4cc_eligible" }
  subject { MarkProductsAsHc4ccEligible.new(given_task_name, double(:current_scope => nil)) }

  let!(:products) do
    FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :csr_00,
                           :benefit_market_kind => :aca_individual,
                           :is_hc4cc_plan => false)
  end
  let!(:plans) { FactoryBot.create_list(:plan, 5, :csr_00, :with_premium_tables, market: 'individual', :is_hc4cc_plan => false) }
  let(:file_name) { File.expand_path("#{Rails.root}/spec/test_data/hc4cc_eligible_plans.csv") }

  before do
    headers = ["HiosId", "CsrVarient", "ActiveYear"]
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << headers
      products.each { |product| csv << [product.hios_base_id, product.csr_variant_id, product.active_year] }
      plans.each { |plan| csv << [plan.hios_base_id, plan.csr_variant_id, plan.active_year] }
    end
  end

  after :all do
    file_name = File.expand_path("#{Rails.root}/spec/test_data/hc4cc_eligible_plans.csv")
    File.delete(file_name) if File.exist?(file_name)
    DatabaseCleaner.clean
  end

  around do |example|
    ClimateControl.modify file_name: "spec/test_data/hc4cc_eligible_plans.csv" do
      example.run
    end
  end

  it "marks plans as hc4cc eligible" do
    expect(products.map(&:is_hc4cc_plan).any?(true)).to eq false
    expect(plans.map(&:is_hc4cc_plan).any?(true)).to eq false
    subject.migrate
    expect(products.map(&:reload).map(&:is_hc4cc_plan).any?(false)).to eq false
    expect(plans.map(&:reload).map(&:is_hc4cc_plan).any?(false)).to eq false
  end
end