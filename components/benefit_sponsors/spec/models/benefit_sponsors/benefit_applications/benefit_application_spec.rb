require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, :dbclean => :after_each do
    let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
    let(:benefit_market)          { site.benefit_markets.first }
    let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:benefit_sponsorship)    { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
    let(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog, service_areas: [service_area]) }

    let(:rating_area)  { create_default(:benefit_markets_locations_rating_area) }
    let(:service_area) { create_default(:benefit_markets_locations_service_area) }
    let(:sic_code)      { "001" }

    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    let(:params) do
      {
        effective_period:         effective_period,
        open_enrollment_period:   open_enrollment_period,
        benefit_sponsor_catalog:  benefit_sponsor_catalog,
      }
    end

    let(:valid_params) do
      {
          effective_period:         effective_period,
          open_enrollment_period:   open_enrollment_period,
          benefit_sponsor_catalog:  benefit_sponsor_catalog,
          recorded_rating_area_id: rating_area.id,
          recorded_service_area_ids:[service_area.id],
          recorded_sic_code: sic_code
      }
    end

    describe "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_fields(:effective_period, :open_enrollment_period, :terminated_on)}
      it { is_expected.to have_field(:expiration_date).of_type(Date)}
      it { is_expected.to have_field(:aasm_state).of_type(Symbol).with_default_value_of(:draft)}
      it { is_expected.to have_field(:fte_count).of_type(Integer).with_default_value_of(0)}
      it { is_expected.to have_field(:pte_count).of_type(Integer).with_default_value_of(0)}
      it { is_expected.to have_field(:msp_count).of_type(Integer).with_default_value_of(0)}
      it { is_expected.to embed_many(:benefit_packages)}

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no effective_period" do
        subject { described_class.new(params.except(:effective_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
          expect(subject.errors[:effective_period].first).to match(/can't be blank/)
        end
      end

      context "with no open_enrollment_period" do
        subject { described_class.new(params.except(:open_enrollment_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
          expect(subject.errors[:open_enrollment_period].first).to match(/can't be blank/)
        end
      end

      context "with no recorded_service_areas" do
        subject { described_class.new(params.except(:recorded_service_areas)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
          expect(subject.errors[:recorded_service_areas].first).to match(/can't be blank/)
        end
      end

      context "with no recorded_rating_area" do
        subject { described_class.new(params.except(:recorded_rating_area)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
          expect(subject.errors[:recorded_rating_area].first).to match(/can't be blank/)
        end
      end

      if ApplicationHelperModStubber.display_sic_field_for_employer?
        context 'with no recorded_sic_code' do
          subject { described_class.new(params.except(:recorded_sic_code)) }

          it 'should not be valid' do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:recorded_sic_code].first).to match(/can't be blank/)
          end
        end
      end

      context "with all required arguments" do
        subject {described_class.new(valid_params) }

        before do
          subject.benefit_sponsorship = benefit_sponsorship
          benefit_sponsorship.save!
        end

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        context "and it is saved" do

          it "should save" do
            expect(subject.save).to eq true
          end

          context "it should be findable" do
            before { subject.save! }
            it "should return the instance" do
              expect(described_class.find(subject.id.to_s)).to eq subject
            end
          end
        end
      end
    end

    describe "Extending an open_enrollment_period", :dbclean => :after_each do
      let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
      let(:benefit_application)     { described_class.new(valid_params) }

      before do
        benefit_application.benefit_sponsorship = benefit_sponsorship
        benefit_application.save!
      end

      context "and the application can transition to open enrollment state" do
        let(:valid_open_enrollment_transition_state)    { :approved }

        before { benefit_application.aasm_state = valid_open_enrollment_transition_state }

        it "transition into open enrollment should be valid" do
          expect(benefit_application.may_begin_open_enrollment?).to eq true
        end

        context "and the new end date is later than effective_period start" do
          let(:late_open_enrollment_end_date)  { effective_period.min + 1.day }

          before do
            benefit_application.extend_open_enrollment_period(late_open_enrollment_end_date)
          end

          it "should not change the open_enrollment_period" do
            expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
          end

          it "should not change the application state" do
            expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
          end
        end

        context "and the new end date is in the past" do
          let(:past_date) { open_enrollment_period_end_on - 1.day }

          before do
            TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period_end_on)
            benefit_application.extend_open_enrollment_period(past_date)
          end

          after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

          it "should be able to transition into open enrollment" do
            expect(benefit_application.may_begin_open_enrollment?).to eq true
          end

          it "should not change the open_enrollment_period" do
            expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
          end

          it "should not change the application state" do
            expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
          end
        end

        context "and the new end date is valid" do
          let(:valid_date)  { effective_period_start_on - 1.day }

          before {
            benefit_application.extend_open_enrollment_period(valid_date)
          }

          it "should change the open_enrollment_period end date and transition into open_enrollment" do
            expect(benefit_application.open_enrollment_end_on).to eq valid_date
            expect(benefit_application.aasm_state).to eq(:enrollment_open)
          end

          context "and the application cannot transition into open_enrollment_state" do
            let(:invalid_open_enrollment_transition_state)  { :draft }

            before do
              benefit_application.open_enrollment_period = open_enrollment_period
              benefit_application.aasm_state = invalid_open_enrollment_transition_state
              benefit_application.extend_open_enrollment_period(valid_date)
            end

            it "transition into open enrollment should be invalid" do
              expect(benefit_application.may_begin_open_enrollment?).to eq false
            end

            it "should not change the open_enrollment_period or transition into open_enrollment" do
              expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
              expect(benefit_application.aasm_state).to eq(invalid_open_enrollment_transition_state)
            end

          end
        end
      end
    end

    describe "Scopes", :dbclean => :after_each do
      let(:this_year)                       { TimeKeeper.date_of_record.year }
      let(:march_effective_date)            { Date.new(this_year,3,1) }
      let(:march_open_enrollment_begin_on)  { march_effective_date - 1.month }
      let(:march_open_enrollment_end_on)    { march_open_enrollment_begin_on + 9.days }
      let(:april_effective_date)            { Date.new(this_year,4,1) }
      let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
      let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

      let!(:march_sponsors)                 { FactoryBot.create_list(:benefit_sponsors_benefit_application, 3,
                                              effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)) )}
      let!(:april_sponsors)                 { FactoryBot.create_list(:benefit_sponsors_benefit_application, 2,
                                              effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)) )}

      before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }


      # it "should find applications by Effective date start" do
      #   expect(BenefitApplications::BenefitApplication.all.size).to eq 5
      #   expect(BenefitApplications::BenefitApplication.effective_date_begin_on(march_effective_date).to_a.sort).to eq march_sponsors.sort
      #   expect(BenefitApplications::BenefitApplication.effective_date_begin_on(april_effective_date).to_a.sort).to eq april_sponsors.sort
      # end

      # it "should find applications by Open Enrollment begin" do
      #   expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(march_open_enrollment_begin_on).to_a.sort).to eq march_sponsors.sort
      #   expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(april_open_enrollment_begin_on).to_a.sort).to eq april_sponsors.sort
      # end

      # it "should find applications by Open Enrollment end" do
      #   # binding.pry
      #   expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(march_open_enrollment_end_on).to_a.sort).to eq march_sponsors.sort
      #   expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(april_open_enrollment_end_on).to_a.sort).to eq april_sponsors.sort
      # end

      # it "should find applications in Plan Draft status" do
      #   expect(BenefitApplications::BenefitApplication.draft.to_a.sort).to eq (march_sponsors + april_sponsors).sort
      # end

      # it "should find applications with chained scopes" do
      #   expect(BenefitApplications::BenefitApplication.
      #                                   draft.
      #                                   open_enrollment_begin_on(april_open_enrollment_begin_on)).to eq april_sponsors
      # end

      it "should find applications in Plan Design Exception status"
      it "should find applications in Plan Design Approved status"
      it "should find applications in Enrolling status"
      it "should find applications in Enrollment Eligible status"
      it "should find applications in Enrollment Ineligible status"
      it "should find applications in Coverage Effective status"
      it "should find applications in Terminated status"
      it "should find applications in Expired Effective status"


      # context "with an application in renewing status" do
      #   let(:last_year)                       { this_year - 1 }
      #   let(:last_march_effective_date)       { Date.new(last_year,3,1) }
      #   let!(:initial_application)            { FactoryBot.create(:benefit_sponsors_benefit_application,
      #                                           effective_period: (last_march_effective_date..(last_march_effective_date + 1.year - 1.day)) )}
      #   let!(:renewal_application)            { FactoryBot.create(:benefit_sponsors_benefit_application,
      #                                           effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)),
      #                                           predecessor_application: initial_application)}

      #   it "should find the renewing application" do
      #     expect(BenefitApplications::BenefitApplication.is_renewing).to eq [renewal_application]
      #     expect(BenefitApplications::BenefitApplication.is_renewing.first.is_renewing?).to eq true
      #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application).to eq initial_application
      #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application.successor_applications).to eq [renewal_application]
      #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application.is_renewing?).to eq false
      #   end
      # end
    end

    describe "Transitioning a BenefitApplication through Plan Design states" do
      let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
      let(:benefit_application)     { described_class.new(valid_params) }


      before do
        benefit_application.benefit_sponsorship = benefit_sponsorship
        benefit_application.save!
      end

      context "Happy path workflow" do

        it "should initialize in state: :draft" do
          expect(benefit_application.aasm_state).to eq :draft
        end

        context "and the application is submitted outside open enrollment period" do
          before { benefit_application.approve_application! }

          it "should transition to state: :approved" do
            expect(benefit_application.aasm_state).to eq :approved
          end

          context "and open enrollment period begins" do
            before {
                TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.min)
                benefit_application.begin_open_enrollment!
              }
            after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

            it "should transition to state: :enrollment_open" do
              expect(benefit_application.aasm_state).to eq :enrollment_open
            end

            context "and open enrollment period ends" do
              before { benefit_application.end_open_enrollment! }

              it "should transition to state: :enrollment_closed" do
                expect(benefit_application.aasm_state).to eq :enrollment_closed
              end

              context "and binder payment is made" do
                before {benefit_application.credit_binder!}

                it "should transition to state :binder_paid" do
                  expect(benefit_application.aasm_state).to eq :binder_paid
                end

                context "and application is eligible" do
                  before { benefit_application.approve_enrollment_eligiblity! }

                  it "should transition to state: :enrollment_eligible" do
                    expect(benefit_application.aasm_state).to eq :enrollment_eligible
                  end

                  context "and effective period begins" do
                    before { benefit_application.activate_enrollment! }

                    it "should transition to state: :approved" do
                      expect(benefit_application.aasm_state).to eq :active
                    end
                  end
                end
              end
            end
          end
        end

        context 'revert reverse_enrollment_eligibility' do
          before do
            benefit_application.update_attributes(aasm_state: :binder_paid)
            benefit_application.reverse_enrollment_eligibility!
          end

          it "should transition to state: :enrollment_closed" do
            expect(benefit_application.aasm_state).to eq :enrollment_closed
          end
        end

        context 'revert benefit_application' do
          before do
            benefit_application.update_attributes(aasm_state: :binder_paid)
            benefit_application.revert_application!
          end

          it "should transition to state: :draft" do
            expect(benefit_application.aasm_state).to eq :draft
          end
        end

        context 'activate_enrollment' do
          before do
            benefit_application.update_attributes(aasm_state: :binder_paid)
            benefit_application.activate_enrollment!
          end

          it "should transition to state: :active" do
            expect(benefit_application.aasm_state).to eq :active
          end
        end
      end

      context "Conversion workflow" do

        it "should initialize in state: :draft" do
          expect(benefit_application.aasm_state).to eq :draft
        end

        context "and its a conversion application" do
          before { benefit_application.import_application! }

          it "should transition to state :imported" do
            expect(benefit_application.aasm_state).to eq :imported
          end

          context "and the application is submitted" do
            before { benefit_application.approve_application! }

            it "should transition to state: :approved" do
              expect(benefit_application.aasm_state).to eq :approved
            end
          end
        end
      end

    end



    ## TODO: Refactor for BenefitApplication
    # context "#to_plan_year", dbclean: :after_each do
    #   let(:benefit_application)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }
    #   let(:benefit_sponsorship)       { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(benefit_market: :aca_shop_cca) }

    #   let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    #   let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    #   let(:office_location) { OfficeLocation.new(
    #       is_primary: true,
    #       address: address,
    #       phone: phone
    #     )
    #   }

    #   let(:plan_design_organization)  { BenefitSponsors::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc") }
    #   let(:plan_design_proposal)      { BenefitSponsors::Organizations::PlanDesignProposal.new(title: "New Proposal") }
    #   let(:profile) {BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new}

    #   before(:each) do
    #     plan_design_organization.plan_design_proposals << [plan_design_proposal]
    #     plan_design_proposal.profile = profile
    #     profile.organization.benefit_sponsorships = [benefit_sponsorship]
    #     benefit_sponsorship.benefit_applications  = [benefit_application]
    #     benefit_application.benefit_packages.build
    #     plan_design_organization.save
    #   end

    #   it "should instantiate a plan year object and must have correct values assigned" do
    #     plan_year = benefit_application.to_plan_year
    #     expect(plan_year.class).to eq PlanYear
    #     expect(plan_year.benefit_groups.present?).to eq true
    #     expect(plan_year.start_on).to eq benefit_application.effective_period.begin
    #     expect(plan_year.end_on).to eq benefit_application.effective_period.end
    #     expect(plan_year.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
    #     expect(plan_year.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
    #   end
    # end

    describe ".renew" do

      context "when renewal benefit sponsor catalog available" do

        # Create site
        # Create benefit market

        # Create employer organization with profile
        # Create benefit sponsorships
        # Create benefit applications
        # Create benefit sponsor catalogs

        let(:renewal_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:current_effective_date) { renewal_effective_date.prev_year }
        let(:effective_period) { current_effective_date..current_effective_date.next_year.prev_day }
        let(:package_kind)            { :single_issuer }

        # let(:benefit_market) { create(:benefit_markets_benefit_market, site_urn: 'mhc', kind: :aca_shop, title: "MA Health Connector SHOP Market") }

        # let(:current_benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
        #   title: "SHOP Benefits for #{current_effective_date.year}",
        #   application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year)
        # )}

        # let(:renewal_benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog,
        #   title: "SHOP Benefits for #{renewal_effective_date.year}",
        #   application_period: (renewal_effective_date.beginning_of_year..renewal_effective_date.end_of_year)
        # )}

        # let(:benefit_sponsorship) { create(:benefit_sponsors_benefit_sponsorship, benefit_market: benefit_market) }

        let!(:employer_profile) {benefit_sponsorship.profile}
        let!(:initial_application) { create(:benefit_sponsors_benefit_application, benefit_sponsor_catalog: benefit_sponsor_catalog, effective_period: effective_period,benefit_sponsorship:benefit_sponsorship, aasm_state: :active) }
        let(:product_package)           { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
        let(:benefit_package)   { create(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package, benefit_application: initial_application) }

        let(:renewal_benefit_sponsor_catalog) { build(:benefit_markets_benefit_sponsor_catalog, effective_date: renewal_effective_date, effective_period: renewal_effective_date..renewal_effective_date.next_year.prev_day, open_enrollment_period: renewal_effective_date.prev_month..(renewal_effective_date - 15.days)) }

        let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: benefit_package.start_on, benefit_group_id:nil, benefit_package_id: benefit_package.id, is_active:true)}
        let!(:census_employee) { FactoryBot.create(:census_employee, employer_profile_id: nil, benefit_sponsors_employer_profile_id: employer_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment]) }

        let!(:renewal_application) {initial_application.renew(renewal_benefit_sponsor_catalog)}
        let(:renewal_bga) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: census_employee, is_active: false)}


        it "should generate renewal application" do
          expect(renewal_application.predecessor).to eq initial_application
          expect(renewal_application.effective_period.begin).to eq renewal_effective_date
          expect(renewal_application.benefit_sponsor_catalog).to eq renewal_benefit_sponsor_catalog
        end

        context "when renewal application saved" do

          before do
            renewal_application.save
            renewal_bga
          end

          it "should create renewal benefit group assignment" do
            expect(census_employee.active_benefit_group_assignment.benefit_application).to eq initial_application
            expect(census_employee.renewal_benefit_group_assignment.benefit_application).to eq renewal_application
          end

          it "renewal benefit group assignment is_active set to false" do
            expect(census_employee.renewal_benefit_group_assignment.is_active).to eq false
            expect(census_employee.active_benefit_group_assignment.is_active).to eq true
          end
        end

        context "when renewal application moved to enrollment_open state" do

          before do
            renewal_bga
            renewal_application.aasm_state = :enrollment_open
            renewal_application.recorded_rating_area=  rating_area
            renewal_application.recorded_service_areas = [service_area]
            renewal_application.recorded_sic_code = sic_code
            renewal_application.save!
          end

          it "should not update benefit group assignments" do
            expect(renewal_application.aasm_state).to eq :enrollment_open

            expect(census_employee.renewal_benefit_group_assignment.is_active).to eq false
            expect(census_employee.renewal_benefit_group_assignment.benefit_application).to eq renewal_application

            expect(census_employee.active_benefit_group_assignment.is_active).to eq true
            expect(census_employee.active_benefit_group_assignment.benefit_application).to eq initial_application
          end
        end

        context "when renewal application moved to active state" do

          before do
            renewal_bga
            renewal_application.aasm_state = :enrollment_eligible
            renewal_application.recorded_rating_area=  rating_area
            renewal_application.recorded_service_areas = [service_area]
            renewal_application.recorded_sic_code = sic_code
            initial_application.update_attributes(predecessor_id: renewal_application.id)
            renewal_application.renew_benefit_package_assignments
            renewal_application.save!
            renewal_application.activate_enrollment!
          end

          it "should activate renewal benefit group assignment & set is_active to true" do
            expect(renewal_application.aasm_state).to eq :active
            renewal_bga = census_employee.benefit_group_assignments.effective_on(renewal_application.effective_period.min).first
            expect(renewal_bga.benefit_application).to eq renewal_application
            expect(census_employee.active_benefit_group_assignment.is_active).to eq true
          end

          xit "should deactivate active benefit group assignment" do
            expect(census_employee.benefit_group_assignments.where(benefit_package_id:benefit_package.id).first.is_active).to eq false
          end
        end
      end
    end

    describe "enrollments_till_given_effective_on" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      context "No hbx_enrollments for the benefit application" do
        it "No hbx_enrollment under the benefit application" do
          expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).to eq 0
        end
      end

      context "HbxEnrollment avalaibale for benefit application return the enrollment with the given date" do
        before do
          enrollment = HbxEnrollment.new(effective_on: Date.today.next_month.beginning_of_month)
          enrollment1 = HbxEnrollment.new(effective_on: Date.today.next_month.beginning_of_month + 2.months)
          benefit_sponsorship.benefit_applications.first.hbx_enrollments << enrollment
          benefit_sponsorship.benefit_applications.first.hbx_enrollments << enrollment1
          benefit_sponsorship.benefit_applications.first.save
        end
        it "Benefit application should have enrollment under the application" do
          expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).not_to eq 0
        end

        it "Benefit application should have enrollment under the application" do
          expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).to eq 2
        end

        it "Should return the enrollments only with the effective date as next month start date" do
          expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month).count).not_to eq 0
        end

        it "should not return enrollment outside given date" do
          expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month).count).to eq 1
        end

        it "should return enrollments within the given date" do
          expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month + 2.months).count).to eq 2
        end
      end
    end

    describe "Date period behaviors" do
      let(:subject)             { BenefitApplications::BenefitApplicationSchedular.new }
      let(:begin_day)           { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }
      let(:grace_begin_day)     { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.days }

      def standard_begin_day
        (begin_day > 0) ? begin_day : 1
      end

      it "should return the day of month deadline for an open enrollment standard period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month).to eq standard_begin_day
      end

      it "should return the day of month deadline for an open enrollment grace period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month(true)).to eq grace_begin_day
      end

      context "and a calendar date is passed to effective period by date method" do
        let(:seed_date)                         { TimeKeeper.date_of_record + 2.months + 3.days }
        let(:next_month_begin_on)               { seed_date.beginning_of_month + 1.month }
        let(:next_month_effective_period)       { next_month_begin_on..(next_month_begin_on + 1.year - 1.day) }
        let(:following_month_begin_on)          { seed_date.beginning_of_month + 2.months }
        let(:following_month_effective_period)  { following_month_begin_on..(following_month_begin_on + 1.year - 1.day) }

        let(:standard_period_last_day)          { subject.open_enrollment_minimum_begin_day_of_month }
        let(:standard_period_deadline_date)     { Date.new(seed_date.year, seed_date.month, standard_period_last_day) }
        let(:standard_period_pre_deadline_date) { standard_period_deadline_date - 1.day }

        let(:grace_period_last_day)             { subject.open_enrollment_minimum_begin_day_of_month(true) }
        let(:grace_period_deadline_date)        { Date.new(seed_date.year, seed_date.month, grace_period_last_day) }
        let(:grace_period_post_deadline_date)   { grace_period_deadline_date + 1.day }


        context "that is before standard period deadline" do
          it "should provide an effective (standard) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_pre_deadline_date)).to eq next_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_pre_deadline_date, true)).to eq next_month_effective_period
          end
        end

        context "that is the same day as the standard period deadline" do
          it "should provide an effective (standard) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_deadline_date)).to eq next_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of next month" do
            expect(subject.effective_period_by_date(standard_period_deadline_date, true)).to eq next_month_effective_period
          end
        end

        # TODO: Open enrollment minimum length setting for days & adv_days same.
        #       Following spec need to be improved to handle this scenario.
        # context "that is after the standard period, but before the grace period deadline" do
        #   it "should provide an effective (standard) period beginning the first of month following next month" do
        #     expect(subject.effective_period_by_date(grace_period_deadline_date)).to eq following_month_effective_period
        #   end

        #   it "should provide an effective (grace) period beginning the of first next month" do
        #     expect(subject.effective_period_by_date(grace_period_deadline_date, true)).to eq next_month_effective_period
        #   end
        # end

        context "that is after both the standard and grace period deadlines" do
          it "should provide an effective (standard) period beginning the first of month following next month" do
            expect(subject.effective_period_by_date(grace_period_post_deadline_date)).to eq following_month_effective_period
          end

          it "should provide an effective (grace) period beginning the first of month following next month" do
            expect(subject.effective_period_by_date(grace_period_post_deadline_date, true)).to eq following_month_effective_period
          end
        end
      end

      context "and an effective date is passed to open enrollment period by effective date method" do
        let(:effective_date)                  { (TimeKeeper.date_of_record + 3.months).beginning_of_month }
        let(:prior_month)                     { effective_date - 1.month }
        let(:valid_open_enrollment_begin_on)  { effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months }
        let(:valid_open_enrollment_end_on)    { Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on) }
        let(:valid_open_enrollment_period)    { valid_open_enrollment_begin_on..valid_open_enrollment_end_on }

        it "should provide a valid open enrollment period for that effective date" do
          expect(subject.open_enrollment_period_by_effective_date(effective_date)).to eq valid_open_enrollment_period
        end
      end

      context "and an effective date is passed to enrollment timetable by effective date method" do
        let(:effective_date)                  { TimeKeeper.date_of_record.next_month.end_of_month + 1.day }

        let(:prior_month)                     { effective_date - 1.month }

        let(:begin_day)                        { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                                Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }

        let(:open_enrollment_end_day)         { Settings.aca.shop_market.open_enrollment.monthly_end_on }
        let(:open_enrollment_end_on)          { Date.new(prior_month.year, prior_month.month, open_enrollment_end_day) }

        let(:late_open_enrollment_begin_on)   { Date.new(prior_month.year, prior_month.month, late_open_enrollment_begin_day) }
        let(:late_open_enrollment_period)     { late_open_enrollment_begin_on..open_enrollment_end_on }

        let(:binder_payment_due_on) {
          Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)
        }

        let(:valid_timetable)                 {
                                                {
                                                    effective_date:                 effective_date,
                                                    effective_period:               effective_date..(effective_date.next_year - 1.day),
                                                    open_enrollment_period:         TimeKeeper.date_of_record..open_enrollment_end_on,
                                                    open_enrollment_period_minimum: late_open_enrollment_period,
                                                    binder_payment_due_on:          binder_payment_due_on
                                                }
                                              }
        def late_open_enrollment_begin_day
          (begin_day > 0) ? begin_day : 1
        end

        it "should provide a valid an enrollment timetabe hash for that effective date" do
          expect(subject.enrollment_timetable_by_effective_date(effective_date)).to eq valid_timetable
        end

        it "timetable date values should be valid" do
          timetable = subject.enrollment_timetable_by_effective_date(effective_date)

          expect(BenefitApplications::BenefitApplication.new(
                              effective_period: timetable[:effective_period],
                              open_enrollment_period: timetable[:open_enrollment_period],
                              recorded_service_areas:  [service_area],
                              recorded_rating_area:    rating_area,
                              recorded_sic_code:       sic_code,
                            )).to be_valid
        end
      end
    end

    describe ".open_enrollment_length" do
      let!(:initial_application) do
        FactoryBot.create(
          :benefit_sponsors_benefit_application,
          benefit_sponsor_catalog: benefit_sponsor_catalog,
          effective_period: effective_period,
          benefit_sponsorship: benefit_sponsorship,
          aasm_state: :active
        )
      end
      let(:min_open_enrollment_length) { 5 }
      let(:start_date) {Date.new(2019,11,16)}
      let(:end_date) {Date.new(2019,11,20)}

      it 'open_enrollment_length should be greater than min_open_enrollment_length' do
        initial_application.update_attributes(open_enrollment_period: (start_date..(end_date + 1.day)))
        expect(initial_application.open_enrollment_length).to be > min_open_enrollment_length
      end

      it 'open_enrollment_length should be equal to min_open_enrollment_length ' do
        initial_application.update_attributes(open_enrollment_period: (start_date..end_date))
        expect(initial_application.open_enrollment_length).to eq min_open_enrollment_length
      end

      it 'open_enrollment_length should be less than min_open_enrollment_length ' do
        initial_application.update_attributes(open_enrollment_period: (start_date..(end_date - 1.day)))
        expect(initial_application.open_enrollment_length).to be < min_open_enrollment_length
      end
    end

    describe "Navigating BenefitSponsorship Predecessor/Successor linked list", :dbclean => :after_each do
      let(:node_a)    { described_class.new(benefit_sponsorship: benefit_sponsorship,
                                                effective_period: effective_period,
                                                open_enrollment_period: open_enrollment_period,
                                                recorded_sic_code: sic_code,
                                                recorded_rating_area: rating_area,
                                                recorded_service_areas: [service_area],
                                              ) }
      let(:node_a1)   { described_class.new(benefit_sponsorship: benefit_sponsorship,
                                                effective_period: effective_period,
                                                open_enrollment_period: open_enrollment_period,
                                                recorded_sic_code: sic_code,
                                                recorded_rating_area: rating_area,
                                                recorded_service_areas: [service_area],
                                                predecessor: node_a,
                                              ) }
      let(:node_a1a)  { described_class.new(benefit_sponsorship: benefit_sponsorship,
                                                effective_period: effective_period,
                                                open_enrollment_period: open_enrollment_period,
                                                recorded_sic_code: sic_code,
                                                recorded_rating_area: rating_area,
                                                recorded_service_areas: [service_area],
                                                predecessor: node_a1,
                                              ) }
      let(:node_b1)   { described_class.new(benefit_sponsorship: benefit_sponsorship,
                                                effective_period: effective_period,
                                                open_enrollment_period: open_enrollment_period,
                                                recorded_sic_code: sic_code,
                                                recorded_rating_area: rating_area,
                                                recorded_service_areas: [service_area],
                                                predecessor: node_a,
                                              ) }

      it "should manage predecessors", :aggregate_failures do
        expect(node_a1a.predecessor).to eq node_a1
        expect(node_a1.predecessor).to eq node_a
        expect(node_b1.predecessor).to eq node_a
        expect(node_a.predecessor).to eq nil
      end

      context "and the BenefitApplications are persisted" do
        before do
          node_a.save!
          node_a1.save!
          node_a1a.save!
          node_b1.save!
        end

        it "should maintain linked lists for successors", :aggregate_failures do
          expect(node_a.successors).to contain_exactly(node_a1, node_b1)
          expect(node_a1.successors).to eq [node_a1a]
        end
      end
    end

    describe "after_create actions" do
      let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
      let(:benefit_application)     { described_class.new(valid_params) }

      before do
        benefit_application.benefit_sponsorship = benefit_sponsorship
        benefit_application.save!
      end

      context "for expiration_date" do
        it "should default to min date of effective_period" do
          expect(benefit_application.expiration_date).to eq (benefit_application.effective_period.min)
        end

        it "should not default to max date of effective_period" do
          expect(benefit_application.expiration_date).not_to eq (benefit_application.effective_period.max)
        end
      end
    end

    describe '.enrolled_families',dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees with benefits"

      let!(:people) { create_list(:person, 5, :with_employee_role, :with_family) }

      before do
        people.each_with_index do |person, i|
          ce = census_employees[i]
          family = person.primary_family
          ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
        end
      end

      it 'should return enrolled families count' do
        expect(initial_application.enrolled_families.count).to eq benefit_sponsorship.census_employees.count
      end
    end

    describe '.active_and_cobra_enrolled_families',dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees with benefits"

      let!(:people) { create_list(:person, 5, :with_employee_role, :with_family) }

      before do
        people.each_with_index do |person, i|
          ce = census_employees[i]
          family = person.primary_family
          ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
        end
      end

      it 'should return enrolled families count' do
        expect(initial_application.active_and_cobra_enrolled_families.count).to eq benefit_sponsorship.census_employees.count
      end
    end

    describe '.predecessor_benefit_package', dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      it 'should return predecessor benefit package' do
        expect(renewal_application.predecessor_benefit_package(benefit_package)).to eq current_benefit_package
      end
    end

    describe '.active_census_employees_under_py', dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"
      include_context "setup employees with benefits"

      before :each do
        renewal_application.benefit_packages.first.update_attributes!(_id: CensusEmployee.all.first.benefit_group_assignments.first.benefit_package_id)
      end

      it 'should not return the terminated EEs' do
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
        term_date = renewal_application.effective_period.min - 10.days
        ce = renewal_application.active_census_employees_under_py.first
        ce.benefit_group_assignments.first.update_attributes!(start_on: renewal_application.effective_period.min + 1.day)
        ce.aasm_state = 'employment_terminated'
        ce.employment_terminated_on = term_date
        ce.save(validate: false)
        expect(renewal_application.active_census_employees_under_py.count).to eq 4
      end

      it 'should not return term pending with prior effective date as term date' do
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
        term_date = renewal_application.effective_period.min - 10.days
        ce = renewal_application.active_census_employees_under_py.first
        ce.benefit_group_assignments.first.update_attributes!(start_on: renewal_application.effective_period.min + 1.day)
        ce.aasm_state = 'employee_termination_pending'
        ce.employment_terminated_on = term_date
        ce.save(validate: false)
        expect(renewal_application.active_census_employees_under_py.count).to eq 4
      end

      it 'should return term pending with effective date as term date' do
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
        term_date = renewal_application.effective_period.min
        ce = renewal_application.active_census_employees_under_py.first
        ce.aasm_state = 'employee_termination_pending'
        ce.employment_terminated_on = term_date
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
      end

      it 'should return term pending with future effective date as term date' do
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
        term_date = renewal_application.effective_period.min + 1.day
        ce = renewal_application.active_census_employees_under_py.first
        ce.aasm_state = 'employee_termination_pending'
        ce.employment_terminated_on = term_date
        expect(renewal_application.active_census_employees_under_py.count).to eq 5
      end
    end

    describe '.successor_benefit_package', dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      it 'should return successor benefit package' do
        expect(predecessor_application.successor_benefit_package(current_benefit_package)).to eq benefit_package
      end
    end

    describe 'quiet period end date for intial and renewal application', dbclean: :after_each do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      context ".renewal_quiet_period_end", dbclean: :after_each do
        it 'should return renewal quiet period dates' do
          renewal_quiet_period = renewal_application.start_on + (Settings.aca.shop_market.renewal_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.renewal_application.quiet_period.mday - 1).days
          expect(renewal_application.renewal_quiet_period_end(renewal_application.start_on).mday).to eq 15
          expect(renewal_application.renewal_quiet_period_end(renewal_application.start_on)).to eq renewal_quiet_period
        end
      end

      context ".initial_quiet_period_end", dbclean: :after_each do
        it 'should return initial quiet period dates' do
          inital_quiet_period = predecessor_application.start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
          expect(predecessor_application.initial_quiet_period_end(predecessor_application.start_on).mday).to eq 28
          expect(predecessor_application.initial_quiet_period_end(predecessor_application.start_on)).to eq inital_quiet_period
        end
      end
    end

    describe '.open_enrollment_date_bounds', dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      context "when DATE is After default OE" do

        before do
          prior_month = renewal_application.start_on - 1.month
          TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 14))
        end
        after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

        context ".renewal open_enrollment_date_bound", dbclean: :after_each do

          it 'should return renewal open_enrollment dates' do
            renewal_start_on = renewal_application.start_on
            renewal_open_enrollment_date_bound = renewal_application.open_enrollment_date_bounds

            expect(renewal_open_enrollment_date_bound[:min]).to eq TimeKeeper.date_of_record
            expect(renewal_open_enrollment_date_bound[:max]).to eq renewal_start_on.end_of_month
          end
        end

        context ".initial open_enrollment_date_bound", dbclean: :after_each do

          before do
            prior_month = predecessor_application.start_on - 1.month
            TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 14))
          end
          after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

          it 'should return initial open_enrollment dates' do
            inital_start_on = predecessor_application.start_on
            inital_open_enrollment_date_bound = predecessor_application.open_enrollment_date_bounds

            expect(inital_open_enrollment_date_bound[:min]).to eq TimeKeeper.date_of_record
            expect(inital_open_enrollment_date_bound[:max]).to eq inital_start_on.end_of_month
          end
        end
      end

      context "when DATE is Before default OE date" do

        before do
          prior_month = renewal_application.start_on - 1.month
          TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 9))
        end
        after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

        context ".renewal open_enrollment_date_bound", dbclean: :after_each do

          it 'should return renewal open_enrollment dates' do
            renewal_start_on = renewal_application.start_on
            prior_month = renewal_application.start_on - 1.month
            renewal_open_enrollment_date_bound = renewal_application.open_enrollment_date_bounds

            expect(renewal_open_enrollment_date_bound[:min]).to eq Date.new(prior_month.year, prior_month.month, 13)
            expect(renewal_open_enrollment_date_bound[:max]).to eq renewal_start_on.end_of_month
          end
        end

        context ".initial open_enrollment_date_bound", dbclean: :after_each do

          before do
            prior_month = predecessor_application.start_on - 1.month
            TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 9))
          end
          after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

          it 'should return initial open_enrollment dates' do
            inital_start_on = predecessor_application.start_on
            prior_month = predecessor_application.start_on - 1.month
            inital_open_enrollment_date_bound = predecessor_application.open_enrollment_date_bounds

            expect(inital_open_enrollment_date_bound[:min]).to eq Date.new(prior_month.year, prior_month.month, 10)
            expect(inital_open_enrollment_date_bound[:max]).to eq inital_start_on.end_of_month
          end
        end
      end

    end

    describe '.enrollment_quiet_period', dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }

      context "when intital application open enrollment end date inside plan year start date", dbclean: :after_each do

        it 'return next day of open_enrollment_end date as quiet_period start date' do
          quiet_period = initial_application.enrollment_quiet_period
          expect(quiet_period.min.to_date).to eq initial_application.open_enrollment_period.max + 1.day
        end

        it 'return default quiet_period end date' do
          quiet_period = initial_application.enrollment_quiet_period
          initial_quiet_period_end = initial_application.start_on + Settings.aca.shop_market.initial_application.quiet_period.month_offset.months + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
          expect(quiet_period.max).to eq TimeKeeper.end_of_exchange_day_from_utc(initial_quiet_period_end)
        end
      end

      context "when intital application open enrollment end date outside plan year start date", dbclean: :after_each do

        before do
          initial_application.open_enrollment_period = (current_effective_date - 15.days..current_effective_date + 4.days)
          initial_application.save
        end

        it 'return next day of open_enrollment_end date as quiet_period start date' do
          quiet_period = initial_application.enrollment_quiet_period
          expect(quiet_period.min.to_date).to eq initial_application.open_enrollment_period.max + 1.day
        end

        it 'return next day of quiet_period start date as quiet_period end date' do
          quiet_period = initial_application.enrollment_quiet_period
          expect(quiet_period.max).to eq quiet_period.min + 1.day
        end

      end
    end

  end
end
