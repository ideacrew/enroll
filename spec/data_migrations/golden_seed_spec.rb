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

    filename = "#{Rails.root}/ivl_testbed_scenarios_*.csv"
    ivl_testbed_templates = Dir.glob(filename)
    if ivl_testbed_templates.present?
      context "with csv input", dbclean: :after_each do
        context "financial assistance" do
          before :each do
            EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(true)
            subject.migrate
          end
          context "requirements" do

            it "should create financial assistance applications" do
              expect(FinancialAssistance::Application.all.count).to be > 0
            end
            xit "should create completed financial assistance applications" do
              expect(FinancialAssistance::Application.where(:family_id.ne => nil, aasm_state: "submitted").count).to be > 0
            end

            xit "should create all relationships for financial assistance applications" do
              FinancialAssistance::Application.all.each do |fa_app|
                family = Family.where(id: fa_app.family_id).first
                puts("Financial App complete for #{family.primary_person}") if family.present?
                expect(fa_app.complete?).to eq(true)
              end
            end

            it "should create financial assistance applicants" do
              expect(FinancialAssistance::Application.all.map(&:applicants).flatten.count).to be > 0
            end

            it "should create incomes" do
              expect(
                FinancialAssistance::Application.all.map(&:applicants).flatten.map(&:incomes).flatten.count
              ).to be > 0
            end

            it "should create job incomes with employer names, address, and phone number" do
              random_job_income = FinancialAssistance::Application.all.map(&:applicants).flatten.map(&:incomes).flatten.detect do |income|
                income.employer_name.present?
              end
              expect(random_job_income.present?).to eq(true)
              expect(random_job_income.employer_phone).to_not be_nil
              expect(random_job_income.employer_address).to_not be_nil
            end

            it "should create hbx enrollments with applied_aptc_amount" do
              expect(HbxEnrollment.where(:applied_aptc_amount.ne => nil).count).to be > 0
            end

            it "should create person records with financial_assistance_identifier attributes" do
              expect(Person.all.select { |person| person.financial_assistance_identifier.present? }).to_not eq(nil)
            end

            it "should create non configued state addresses for people temporarily out of state" do
              temp_out_of_state_person_address = Person.where(is_temporarily_out_of_state: true).all.sample

              temp_out_of_state_address = temp_out_of_state_person_address.addresses.last
              configured_state = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
              expect(temp_out_of_state_address.state).to_not eq(configured_state)
            end
          end
        end

        context "requirements" do
          before :each do
            subject.migrate
          end

          it "should set some to is_applying_for_assistance" do
            expect(Person.all.detect(&:is_applying_for_assistance).present?).to eq(true)
          end

          it "sets some people temporarily absent and no dc address type" do
            expect(Person.all.detect(&:no_dc_address).present?).to eq(true)
            expect(Person.all.detect(&:is_temporarily_out_of_state).present?).to eq(true)
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
    context "without csv input", dbclean: :after_each do
      describe "requirements" do
        before :each do
          allow(subject).to receive(:ivl_testbed_scenario_csv).and_return(nil)
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
end