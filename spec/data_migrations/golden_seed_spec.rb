# frozen_string_literal: true

require "rails_helper"
# require 'rake'

require File.join(Rails.root, "app", "data_migrations", "golden_seed_individual")
require File.join(Rails.root, "components", "benefit_sponsors", "spec", "support", "benefit_sponsors_site_spec_helpers")
require File.join(Rails.root, "app", "data_migrations", "load_issuer_profiles")

# TODO: This will all be deprecated since Golden Seed will be a UI facing task
# TODO: Deprecating this since its moving to a UI function
describe "Golden Seed Rake Tasks", dbclean: :after_all do
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
      context "with csv input" do
        context "financial assistance" do
          before :all do
            Rails.application.load_tasks
            Rake::Task['migrations:golden_seed_individual'].invoke
          end
          context "requirements" do
            let(:fa_applications) { FinancialAssistance::Application.all }
            let(:fa_applicants) { fa_applications.flat_map(&:applicants) }
            let(:fa_incomes) { fa_applicants.flat_map(&:incomes) }
            it "should create financial assistance applications" do
              expect(fa_applications.count).to be > 0
            end

            it "should create financial assistance applicants" do
              expect(fa_applicants.flatten.count).to be > 0
            end

            it "should create incomes" do
              expect(fa_incomes.flatten.count).to be > 0
            end

            it "should set a kind for all incomes" do
              expect(fa_incomes.flatten.detect { |income| income.kind.blank? }.blank?).to eq(true)
            end

            it "should create other incomes with specific kinds for applicants with other income selected" do
              other_income_applicant = fa_applicants.detect do |applicant|
                applicant.has_other_income == true
              end
              expect(other_income_applicant.incomes.present?).to eq(true)
            end

            it "should create job incomes with employer names, address, and phone number" do
              random_job_income = fa_incomes.detect do |income|
                income.employer_name.present?
              end
              expect(random_job_income.present?).to eq(true)
              expect(random_job_income.employer_phone).to_not be_nil
              expect(random_job_income.employer_address).to_not be_nil
            end

            it "should create person records with financial_assistance_identifier attributes" do
              expect(Person.all.select { |person| person.financial_assistance_identifier.present? }).to_not eq(nil)
            end

            it "should set applicant records for pregnancy/post partum" do
              expect(
                fa_applicants.detect do |applicant|
                  applicant.is_pregnant == true &&
                  applicant.is_post_partum_period == true &&
                  applicant.pregnancy_due_on.present?
                end.present?
              ).to eq(true)
            end

            it "should have applicant coverage questions answered" do
              expect(fa_applicants.detect { |applicant| applicant.is_applying_coverage.present? }.present?).to eq(true)
            end

            it "should create addresses for person records" do
              expect(Person.all.detect { |person| person.addresses.present? }).to_not be_nil
            end

            it "should create non configued state addresses for people temporarily out of state" do
              temp_out_of_state_address = Person.where(is_temporarily_out_of_state: true).all.flat_map(&:addresses).sample
              configured_state = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
              expect(temp_out_of_state_address.state).to_not eq(configured_state)
            end
          end
        end

        context "requirements" do
          let(:people) { Person.all }
          before :all do
            Rails.application.load_tasks
            Rake::Task['migrations:golden_seed_individual'].invoke
          end

          it "should create hbx enrollments with applied_aptc_amount" do
            expect(HbxEnrollment.where(:applied_aptc_amount.ne => nil).count).to be > 0
          end

          it "should set some to is_applying_for_assistance" do
            expect(Person.where(:is_applying_for_assistance.ne => nil).present?).to_not be_nil
          end

          it "sets some people temporarily absent and no dc address type" do
            expect(people.detect(&:no_dc_address).present?).to eq(true)
            expect(people.detect(&:is_temporarily_out_of_state).present?).to eq(true)
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
            consumer_roles = people.select { |person| person.consumer_role.present? }
            expect(consumer_roles.count).to_not be(0)
          end

          it "should create users for consumers" do
            consumer_roles = people.select { |person| person.consumer_role.present? }
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
    context "without csv input", dbclean: :before_all do
      describe "requirements" do
        let(:people) { Person.all }
        before do
          Rails.application.load_tasks
          allow_any_instance_of(GoldenSeedIndividual).to receive(:ivl_testbed_scenario_csv).and_return(nil)
        end
        it "will not create new hbx profile and benefit sponsorship if they are already present" do
          Rake::Task['migrations:golden_seed_individual'].invoke
          hbx_profile_count = HbxProfile.all.count
          Rake::Task['migrations:golden_seed_individual'].invoke
          expect(hbx_profile_count == HbxProfile.all.count).to eq(true)
          expect(HbxProfile.all.map(&:benefit_sponsorship).count).to eq(1)
        end

        it "should create at least one IVL health product if none exist" do
          Rake::Task['migrations:golden_seed_individual'].invoke
          products = BenefitMarkets::Products::Product.all.select { |product| product.benefit_market_kind.to_sym == :aca_individual }
          expect(products.count).to_not be(0)
        end

        it "should create fully matched consumer records with users" do
          Rake::Task['migrations:golden_seed_individual'].invoke
          consumer_roles = people.select { |person| person.consumer_role.present? }
          expect(consumer_roles.count).to_not be(0)
          consumer_person_ids = consumer_roles.map(&:_id)
          consumer_users = User.all.select { |user| consumer_person_ids.include?(user.person_id) }
          expect(consumer_users.length).to be > 1
        end

        it "should create active enrollments" do
          Rake::Task['migrations:golden_seed_individual'].invoke
          expect(HbxEnrollment.enrolled.count).to be > 1
        end
      end
    end
  end
end
