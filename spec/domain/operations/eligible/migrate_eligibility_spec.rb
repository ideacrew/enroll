# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe Operations::Eligible::MigrateEligibility,
               type: :model,
               dbclean: :after_each do
  describe "group migrations" do
    include_context "setup benefit market with market catalogs and product packages"

    let(:site) do
      ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
    end
    let(:employer_organization) do
      FactoryBot.create(
        :benefit_sponsors_organizations_general_organization,
        :with_aca_shop_cca_employer_profile,
        site: site
      )
    end
    let(:employer_profile) { employer_organization.employer_profile }

    let!(:benefit_sponsorship) do
      sponsorship = employer_profile.add_benefit_sponsorship
      sponsorship.save!
      sponsorship
    end

    let(:eligibility_options) do
      {
        eligibility_id: BSON.ObjectId("648c68f288d2410568c95990"),
        eligibility_type:
          "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
        start_on: Date.today,
        status: nil,
        title: nil,
        created_at: DateTime.now,
        updated_at: DateTime.now
      }
    end

    let(:evidence_options) do
      {
        is_satisfied: true,
        key: :osse_subsidy,
        title: "Evidence for Osse Subsidy",
        created_at: DateTime.now,
        updated_at: DateTime.now
      }
    end

    let(:grant_options) do
      {
        key: :minimum_participation_rule,
        title: "minimum_participation_rule_relaxed_2023",
        start_on: Date.today,
        created_at: DateTime.now,
        updated_at: DateTime.now
      }
    end

    let(:subject_options) do
      {
        key: benefit_sponsorship.to_global_id.to_s,
        klass: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
        title: "Subject for Osse Subsidy"
      }
    end

    let(:value_options) do
      {
        key: :minimum_participation_rule,
        title: "minimum_participation_rule_relaxed_2023",
        value: "minimum_participation_rule"
      }
    end

    let(:catalog_eligibility) do
      catalog_eligibility =
        ::Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: current_benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date:
              current_benefit_market_catalog.application_period.begin.to_date,
            domain_model:
              "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

      catalog_eligibility
    end

    let(:eligibility) do
      subject = OpenStruct.new(subject_options)
      eligibility = OpenStruct.new(eligibility_options)
      evidence = OpenStruct.new(evidence_options)
      value = OpenStruct.new(value_options)
      grant = OpenStruct.new(grant_options)
      grant.value = value

      eligibility.evidences = [evidence]
      eligibility.grants = [grant]
      eligibility.subject = subject
      eligibility
    end

    let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_effective_date)
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      catalog_eligibility
    end

    after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    context "when existing eligibility record passed with subject" do
      it "should migrate eligibility into new models" do
        result =
          described_class.new.call(
            current_eligibilities: [eligibility],
            eligibility_type:
              "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          )

        expect(result.success?).to be_truthy
        benefit_sponsorship.reload
        eligibility = benefit_sponsorship.eligibilities.last
        expect(eligibility).to be_present

        evidence = eligibility.evidences.last
        expect(evidence.is_satisfied).to be_truthy

        expect(
          evidence.state_histories.pluck(
            :is_eligible,
            :effective_on,
            :from_state,
            :to_state,
            :event
          )
        ).to eq [
             [
               false,
               Date.today.beginning_of_year,
               :initial,
               :initial,
               :move_to_initial
             ],
             [true, Date.today, :initial, :approved, :move_to_approved]
           ]
      end
    end
  end

  describe "individual migrations" do
    let(:coverage_year) { 2023 }

    let(:hbx_profile) do
      FactoryBot.create(
        :hbx_profile,
        :normal_ivl_open_enrollment,
        :last_years_coverage_period,
        coverage_year: coverage_year
      )
    end

    let(:benefit_coverage_period) do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
        (bcp.start_on.year == coverage_year) &&
          bcp.start_on > bcp.open_enrollment_start_on
      end
    end

    let(:last_year_benefit_coverage_period) do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
        (bcp.start_on.year == coverage_year - 1) &&
          bcp.start_on > bcp.open_enrollment_start_on
      end
    end

    let(:catalog_eligibility) do
      Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: benefit_coverage_period.to_global_id,
          eligibility_feature: "aca_ivl_osse_eligibility",
          effective_date: benefit_coverage_period.start_on.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    let(:last_year_catalog_eligibility) do
      Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: last_year_benefit_coverage_period.to_global_id,
          eligibility_feature: "aca_ivl_osse_eligibility",
          effective_date: last_year_benefit_coverage_period.start_on.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    let(:person) do
      FactoryBot.create(:person, :with_family, :with_consumer_role)
    end

    let!(:consumer_role) { person.consumer_role }

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      last_year_catalog_eligibility
      catalog_eligibility
    end

    context ".scenario 1 (multiple eligibilities)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("64cc0283e6d3630010ac6eb8"),
          "start_on" => DateTime.parse("2023-08-03 00:00:00 UTC"),
          "eligibility_id" => BSON.ObjectId("5fd1083bcc35a8263f5d4241"),
          "eligibility_type" => "ConsumerRole",
          "updated_at" => DateTime.parse("2023-08-07 17:27:14 UTC"),
          "created_at" => DateTime.parse("2023-08-03 19:39:47 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("64cc0283e6d3630010ac6eb9"),
            "title" => "Subject for Osse Subsidy",
            "key" => consumer_role.to_global_id.to_s,
            "klass" => "ConsumerRole",
            "updated_at" => DateTime.parse("2023-08-03 19:39:47 UTC"),
            "created_at" => DateTime.parse("2023-08-03 19:39:47 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("64cc0283e6d3630010ac6eba"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2023-08-03 19:39:47 UTC"),
              "created_at" => DateTime.parse("2023-08-03 19:39:47 UTC")
            },
            {
              "_id" => BSON.ObjectId("64d12972901e5000100cb290"),
              "title" => "Osse Subsidy Evidence",
              "key" => :osse_subsidy,
              "is_satisfied" => false,
              "updated_at" => DateTime.parse("2023-08-07 17:27:14 UTC"),
              "created_at" => DateTime.parse("2023-08-07 17:27:14 UTC")
            }
          ],
          "end_on" => DateTime.parse("2023-08-07 00:00:00 UTC")
        }
      end

      let(:options2) do
        {
          "_id" => BSON.ObjectId("64d129775586d40010f663d7"),
          "start_on" => Date.new(2023, 1, 1).beginning_of_day,
          "eligibility_id" => BSON.ObjectId("5fd1083bcc35a8263f5d4241"),
          "eligibility_type" => "ConsumerRole",
          "updated_at" => DateTime.parse("2023-08-07 17:27:19 UTC"),
          "created_at" => DateTime.parse("2023-08-07 17:27:19 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("64d129775586d40010f663d8"),
            "title" => "Subject for Osse Subsidy",
            "key" => consumer_role.to_global_id.to_s,
            "klass" => "ConsumerRole",
            "updated_at" => DateTime.parse("2023-08-07 17:27:19 UTC"),
            "created_at" => DateTime.parse("2023-08-07 17:27:19 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("64d129775586d40010f663d9"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2023-08-07 17:27:19 UTC"),
              "created_at" => DateTime.parse("2023-08-07 17:27:19 UTC")
            }
          ]
        }
      end

      context "when multiple eligibilities present" do
        let(:eligibilities) do
          [options1, options2].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibilities with state histories" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type: "ConsumerRole"
            )

          expect(result.success).to be_truthy
          consumer_role.reload
          expect(consumer_role.eligibilities).to be_present
          expect(consumer_role.eligibilities.count).to eq 1
          eligibility = consumer_role.eligibilities.first
          expect(eligibility.effective_on).to eq eligibilities
            .last
            .start_on
            .to_date
          expect(eligibility.is_eligible).to be_truthy
        end
      end
    end

    context ".scenario 2 (eligibility span across multiple years)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("633b17340d0c8e0010da8d39"),
          "start_on" => Date.new(2022, 10, 0o3).beginning_of_day,
          "eligibility_id" => BSON.ObjectId("61531f59cc35a84225a8de3c"),
          "eligibility_type" => "ConsumerRole",
          "updated_at" => DateTime.parse("2023-05-09 18:03:14 UTC"),
          "created_at" => DateTime.parse("2022-10-03 17:09:08 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("633b17340d0c8e0010da8d3a"),
            "title" => "Subject for Osse Subsidy",
            "key" => consumer_role.to_global_id.to_s,
            "klass" => "ConsumerRole",
            "updated_at" => DateTime.parse("2022-10-03 17:09:08 UTC"),
            "created_at" => DateTime.parse("2022-10-03 17:09:08 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("633b17340d0c8e0010da8d3b"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-10-03 17:09:08 UTC"),
              "created_at" => DateTime.parse("2022-10-03 17:09:08 UTC")
            },
            {
              "_id" => BSON.ObjectId("645a8ae240810d0010e5213e"),
              "title" => "Osse Subsidy Evidence",
              "key" => :osse_subsidy,
              "is_satisfied" => false,
              "updated_at" => DateTime.parse("2023-05-09 18:03:14 UTC"),
              "created_at" => DateTime.parse("2023-05-09 18:03:14 UTC")
            }
          ],
          "end_on" => DateTime.parse("2023-05-09 00:00:00 UTC")
        }
      end

      context "when eligibility with mulitiple years present" do
        let(:eligibilities) do
          [options1].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibilities with state histories" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type: "ConsumerRole"
            )

          expect(result.success).to be_truthy
          consumer_role.reload

          expect(consumer_role.eligibilities).to be_present
          expect(consumer_role.eligibilities.count).to eq 2

          eligibility_2022 =
            consumer_role
            .eligibilities
            .by_key(:aca_ivl_osse_eligibility_2022)
            .first
          eligibility_2023 =
            consumer_role
            .eligibilities
            .by_key(:aca_ivl_osse_eligibility_2023)
            .first

          expect(eligibility_2022.is_eligible).to be_truthy
          expect(eligibility_2022.effective_on.to_date).to eq Date.new(
            2022,
            10,
            3
          )
          expect(eligibility_2022.evidences.last.current_state).to eq :approved
          expect(
            eligibility_2022.evidences.last.state_histories.pluck(:to_state)
          ).to eq %i[initial approved]

          expect(eligibility_2023.is_eligible).to be_falsey
          expect(eligibility_2023.effective_on.to_date).to eq Date.new(
            2023,
            5,
            9
          )
          expect(eligibility_2023.evidences.last.current_state).to eq :denied
          expect(
            eligibility_2023.evidences.last.state_histories.pluck(:to_state)
          ).to eq %i[initial denied]
        end
      end
    end

    context ".scenario 3 (eligibility with multiple evidences)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("63989f87a130410010a67bf8"),
          "start_on" => Date.new(2022, 12, 13).beginning_of_day,
          "eligibility_id" => BSON.ObjectId("639697889ce37e00107596ea"),
          "eligibility_type" => "ConsumerRole",
          "updated_at" => DateTime.parse("2022-12-13 16:04:03 UTC"),
          "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("63989f87a130410010a67bf9"),
            "title" => "Subject for Osse Subsidy",
            "key" => consumer_role.to_global_id.to_s,
            "klass" => "ConsumerRole",
            "updated_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
            "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("63989f87a130410010a67bfa"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
              "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC")
            },
            {
              "_id" => BSON.ObjectId("6398a273f343d300103b84b7"),
              "title" => "Osse Subsidy Evidence",
              "key" => :osse_subsidy,
              "is_satisfied" => false,
              "updated_at" => DateTime.parse("2022-12-13 16:04:03 UTC"),
              "created_at" => DateTime.parse("2022-12-13 16:04:03 UTC")
            }
          ],
          "end_on" => DateTime.parse("2022-12-13 00:00:00 UTC")
        }
      end

      context "when eligibility with mulitiple evidences present" do
        let(:eligibilities) do
          [options1].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibility record" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type: "ConsumerRole"
            )

          expect(result.success).to be_truthy
          consumer_role.reload

          expect(consumer_role.eligibilities).to be_present
          expect(consumer_role.eligibilities.count).to eq 1

          eligibility_2022 =
            consumer_role
            .eligibilities
            .by_key(:aca_ivl_osse_eligibility_2022)
            .first

          eligibility_2022.tap do |e|
            expect(e.is_eligible).to be_falsey
            expect(e.effective_on.to_date).to eq Date.new(2022, 12, 13)
            expect(e.evidences.last.current_state).to eq :denied
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
                 denied
               ]
          end
        end
      end
    end

    context ".scenario 4 (eligibility still active at the end of year)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("63989f87a130410010a67bf8"),
          "start_on" => Date.new(2022, 12, 13).beginning_of_day,
          "eligibility_id" => BSON.ObjectId("639697889ce37e00107596ea"),
          "eligibility_type" => "ConsumerRole",
          "updated_at" => DateTime.parse("2022-12-13 16:04:03 UTC"),
          "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("63989f87a130410010a67bf9"),
            "title" => "Subject for Osse Subsidy",
            "key" => consumer_role.to_global_id.to_s,
            "klass" => "ConsumerRole",
            "updated_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
            "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("63989f87a130410010a67bfa"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-12-13 15:51:35 UTC"),
              "created_at" => DateTime.parse("2022-12-13 15:51:35 UTC")
            }
          ]
        }
      end

      context "when eligibility active last year" do
        let(:eligibilities) do
          [options1].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibility record and create renewal eligibility" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type: "ConsumerRole"
            )

          expect(result.success).to be_truthy
          consumer_role.reload

          expect(consumer_role.eligibilities).to be_present
          expect(consumer_role.eligibilities.count).to eq 2

          eligibility_2022 =
            consumer_role
            .eligibilities
            .by_key(:aca_ivl_osse_eligibility_2022)
            .first
          eligibility_2023 =
            consumer_role
            .eligibilities
            .by_key(:aca_ivl_osse_eligibility_2023)
            .first

          eligibility_2022.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq Date.new(2022, 12, 13)
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
               ]
          end

          eligibility_2023.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq Date.new(2023, 1, 1)
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
               ]
          end
        end
      end
    end
  end

  describe "shop migrations" do
    include_context "setup benefit market with market catalogs and product packages"

    let(:site) do
      ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
    end
    let(:employer_organization) do
      FactoryBot.create(
        :benefit_sponsors_organizations_general_organization,
        :with_aca_shop_cca_employer_profile,
        site: site
      )
    end
    let(:employer_profile) { employer_organization.employer_profile }

    let!(:benefit_sponsorship) do
      sponsorship = employer_profile.add_benefit_sponsorship
      sponsorship.save!
      sponsorship
    end

    let(:past_benefit_market_catalog) do
      market_catalogs = benefit_market.benefit_market_catalogs
      market_catalogs.where(
        "application_period.min" => current_effective_date.prev_year
      ).first
    end

    let(:catalog_eligibility) do
      catalog_eligibility =
        ::Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: current_benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date:
              current_benefit_market_catalog.application_period.begin.to_date,
            domain_model:
              "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

      catalog_eligibility
    end

    let(:past_catalog_eligibility) do
      catalog_eligibility =
        ::Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: past_benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date:
              past_benefit_market_catalog.application_period.begin.to_date,
            domain_model:
              "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

      catalog_eligibility
    end

    let(:past_effective_date) { Date.new(Date.today.year, 1, 1).prev_year }
    let(:current_effective_date) { Date.new(Date.today.year, 1, 1) }

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_effective_date)
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      catalog_eligibility
      past_catalog_eligibility
    end

    after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    context ".scenario 1 (eligibility still active at the end of year)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("633db44976827000105abfcb"),
          "start_on" => DateTime.parse("2022-10-05 00:00:00 UTC"),
          "eligibility_id" => BSON.ObjectId("6335c3a8f356ed00104446f3"),
          "eligibility_type" =>
            "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
          "updated_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
          "created_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("633db44976827000105abfcc"),
            "title" => "Subject for Osse Subsidy",
            "key" => benefit_sponsorship.to_global_id,
            "klass" =>
              "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
            "updated_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
            "created_at" => DateTime.parse("2022-10-05 16:43:53 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("633db44976827000105abfcd"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
              "created_at" => DateTime.parse("2022-10-05 16:43:53 UTC")
            }
          ],
          "grants" => [
            {
              "_id" => BSON.ObjectId("633db44976827000105abfcf"),
              "title" => "minimum_participation_rule_relaxed_2022",
              "key" => :minimum_participation_rule,
              "start_on" => DateTime.parse("2022-10-05 00:00:00 UTC"),
              "updated_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
              "created_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
              "value" => {
                "_id" => BSON.ObjectId("633db44976827000105abfce"),
                "_type" => "Eligibilities::Osse::BenefitSponsorshipOssePolicy",
                "title" => "minimum_participation_rule_relaxed_2022",
                "key" => :minimum_participation_rule,
                "value" => "minimum_participation_rule",
                "updated_at" => DateTime.parse("2022-10-05 16:43:53 UTC"),
                "created_at" => DateTime.parse("2022-10-05 16:43:53 UTC")
              }
            }
          ]
        }
      end

      context "when eligibility active last year" do
        let(:eligibilities) do
          [options1].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibility record and create renewal eligibility" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type:
                "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
            )

          expect(result.success).to be_truthy
          benefit_sponsorship.reload
          expect(benefit_sponsorship.eligibilities).to be_present
          expect(benefit_sponsorship.eligibilities.count).to eq 2

          eligibility_2022 =
            benefit_sponsorship
            .eligibilities
            .by_key(:aca_shop_osse_eligibility_2022)
            .first
          eligibility_2023 =
            benefit_sponsorship
            .eligibilities
            .by_key(:aca_shop_osse_eligibility_2023)
            .first

          eligibility_2022.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq eligibilities
              .first
              .start_on
              .to_date
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
               ]
          end

          eligibility_2023.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq Date.new(2023, 1, 1)
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
               ]
          end
        end
      end
    end
    context ".scenario 2 (multiple eligibility records present)" do
      let(:options1) do
        {
          "_id" => BSON.ObjectId("636c00ad200ce7001082a14b"),
          "start_on" => DateTime.parse("2022-11-09 00:00:00 UTC"),
          "eligibility_id" => BSON.ObjectId("577beb2f082e761e59000034"),
          "eligibility_type" =>
            "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
          "updated_at" => DateTime.parse("2022-11-14 19:04:36 UTC"),
          "created_at" => DateTime.parse("2022-11-09 19:34:05 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("636c00ad200ce7001082a14c"),
            "title" => "Subject for Osse Subsidy",
            "key" => benefit_sponsorship.to_global_id,
            "klass" =>
              "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
            "updated_at" => DateTime.parse("2022-11-09 19:34:05 UTC"),
            "created_at" => DateTime.parse("2022-11-09 19:34:05 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("636c00ad200ce7001082a14d"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-11-09 19:34:05 UTC"),
              "created_at" => DateTime.parse("2022-11-09 19:34:05 UTC")
            },
            {
              "_id" => BSON.ObjectId("637291447b8cde0010954975"),
              "title" => "Osse Subsidy Evidence",
              "key" => :osse_subsidy,
              "is_satisfied" => false,
              "updated_at" => DateTime.parse("2022-11-14 19:04:36 UTC"),
              "created_at" => DateTime.parse("2022-11-14 19:04:36 UTC")
            }
          ],
          "grants" => [
            {
              "_id" => BSON.ObjectId("636c00ae200ce7001082a14f"),
              "title" => "minimum_participation_rule_relaxed_2022",
              "key" => :minimum_participation_rule,
              "start_on" => DateTime.parse("2022-11-09 00:00:00 UTC"),
              "updated_at" => DateTime.parse("2022-11-09 19:34:06 UTC"),
              "created_at" => DateTime.parse("2022-11-09 19:34:06 UTC"),
              "value" => {
                "_id" => BSON.ObjectId("636c00ae200ce7001082a14e"),
                "_type" => "Eligibilities::Osse::BenefitSponsorshipOssePolicy",
                "title" => "minimum_participation_rule_relaxed_2022",
                "key" => :minimum_participation_rule,
                "value" => "minimum_participation_rule",
                "updated_at" => DateTime.parse("2022-11-09 19:34:06 UTC"),
                "created_at" => DateTime.parse("2022-11-09 19:34:06 UTC")
              }
            }
          ],
          "end_on" => DateTime.parse("2022-11-14 00:00:00 UTC")
        }
      end
      let(:options2) do
        {
          "_id" => BSON.ObjectId("637be926b14b360010fcbe34"),
          "start_on" => DateTime.parse("2022-11-21 00:00:00 UTC"),
          "eligibility_id" => BSON.ObjectId("577beb2f082e761e59000034"),
          "eligibility_type" =>
            "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
          "updated_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
          "created_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
          "subject" => {
            "_id" => BSON.ObjectId("637be926b14b360010fcbe35"),
            "title" => "Subject for Osse Subsidy",
            "key" => benefit_sponsorship.to_global_id,
            "klass" =>
              "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
            "updated_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
            "created_at" => DateTime.parse("2022-11-21 21:09:58 UTC")
          },
          "evidences" => [
            {
              "_id" => BSON.ObjectId("637be926b14b360010fcbe36"),
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
              "created_at" => DateTime.parse("2022-11-21 21:09:58 UTC")
            }
          ],
          "grants" => [
            {
              "_id" => BSON.ObjectId("637be926b14b360010fcbe38"),
              "title" => "minimum_participation_rule_relaxed_2022",
              "key" => :minimum_participation_rule,
              "start_on" => DateTime.parse("2022-11-21 00:00:00 UTC"),
              "updated_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
              "created_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
              "value" => {
                "_id" => BSON.ObjectId("637be926b14b360010fcbe37"),
                "_type" => "Eligibilities::Osse::BenefitSponsorshipOssePolicy",
                "title" => "minimum_participation_rule_relaxed_2022",
                "key" => :minimum_participation_rule,
                "value" => "minimum_participation_rule",
                "updated_at" => DateTime.parse("2022-11-21 21:09:58 UTC"),
                "created_at" => DateTime.parse("2022-11-21 21:09:58 UTC")
              }
            }
          ]
        }
      end
      context "when eligibility active last year" do
        let(:eligibilities) do
          [options1, options2].collect do |options|
            Eligibilities::Osse::Eligibility.new(options)
          end
        end

        it "should migrate eligibility record and create renewal eligibility" do
          result =
            described_class.new.call(
              current_eligibilities: eligibilities,
              eligibility_type:
                "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
            )

          expect(result.success).to be_truthy
          benefit_sponsorship.reload
          expect(benefit_sponsorship.eligibilities).to be_present
          expect(benefit_sponsorship.eligibilities.count).to eq 2

          eligibility_2022 =
            benefit_sponsorship
            .eligibilities
            .by_key(:aca_shop_osse_eligibility_2022)
            .first
          eligibility_2023 =
            benefit_sponsorship
            .eligibilities
            .by_key(:aca_shop_osse_eligibility_2023)
            .first

          eligibility_2022.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq eligibilities[1].start_on.to_date
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
                 denied
                 approved
               ]
          end

          eligibility_2023.tap do |e|
            expect(e.is_eligible).to be_truthy
            expect(e.effective_on.to_date).to eq Date.new(2023, 1, 1)
            expect(e.evidences.last.current_state).to eq :approved
            expect(e.evidences.last.state_histories.pluck(:to_state)).to eq %i[
                 initial
                 approved
               ]
          end
        end
      end
    end
  end
end
