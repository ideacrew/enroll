# frozen_string_literal: true

require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "golden_seed_individual")
require File.join(Rails.root, "components", "benefit_sponsors", "spec", "support", "benefit_sponsors_site_spec_helpers")
require File.join(Rails.root, "app", "data_migrations", "load_issuer_profiles")

describe "Golden Seed Rake Tasks", dbclean: :after_each do
  describe "Generate Consumers and Families for Individual Market" do
    let(:given_task_name) { "golden_seed_individual" }
    subject { GoldenSeedIndividual.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "requirements" do
      before :each do
        subject.migrate
      end

      it "will not create new hbx profile and benefit sponsorship if they are already present" do
        expect(HbxProfile.all.count).to eq(1)
        subject.migrate
        expect(HbxProfile.all.count).to eq(1)
        expect(HbxProfile.all.map(&:benefit_sponsorship).count).to eq(1)
      end

      it "should create at least one IVL health product if none exist" do
        products = BenefitMarkets::Products::Product.all.select { |product| product.benefit_market_kind.to_sym == :aca_individual }
        expect(products.count).to_not be(0)
      end

      it "should create fully matched consumer records" do
        consumer_roles = Person.all.select { |person| person.consumer_role.present? }
        expect(consumer_roles.count).to_not be(0)
      end

      it "should create users for consumers" do
        consumer_roles = Person.all.select { |person| person.consumer_role.present? }
        consumer_person_ids = consumer_roles.map(&:_id)
        consumer_users = User.all.select { |user| consumer_person_ids.include?(user.person_id) }
        expect(consumer_users.length).to be > 1
      end

      it "should create active enrollments" do
        expect(HbxEnrollment.enrolled.count).to be > 1
      end
    end
  end
end