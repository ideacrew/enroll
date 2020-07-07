require "rails_helper"
require File.join(File.dirname(__FILE__), "..", "..", "app", "data_migrations", "modify_benefit_application")

RSpec.describe ModifyBenefitApplication, dbclean: :after_each do

  let(:given_task_name) { "modify_benefit_application" }
  subject { ModifyBenefitApplication.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "modifying benefit application", dbclean: :after_each do

    let(:current_effective_date)  { TimeKeeper.date_of_record.beginning_of_month }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                           benefit_market: benefit_market,
                                           title: "SHOP Benefits for #{current_effective_date.year}",
                                           application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
    }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: site.benefit_markets[0],
          employer_attestation: employer_attestation)
    end

    let(:start_on)  { current_effective_date }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let!(:benefit_application) {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package, is_active: true) }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_package)}

    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryGirl.create(:census_employee,
                                               employer_profile: benefit_sponsorship.profile,
                                               benefit_sponsorship: benefit_sponsorship,
                                               benefit_group_assignments: [benefit_group_assignment]
    )}
    let(:person) { FactoryGirl.create(:person) }
    let(:family) { double }
    let(:hbx_enrollment) { double(kind: "employer_sponsored", effective_on: start_on, employee_role_id: employee_role.id,
                                  sponsored_benefit_package_id: benefit_package.id, benefit_group_assignment_id: benefit_group_assignment.id,
                                  aasm_state: 'coverage_selected') }

    around do |example|
      ClimateControl.modify fein: organization.fein do
        example.run
      end
    end

    context "extend open enrollment" do

      let!(:current_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let!(:start_on)  { current_effective_date }
      let!(:effective_period)  { start_on..start_on.next_year.prev_day }
      let!(:ineligible_benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: "enrollment_ineligible", effective_period: effective_period)}

      around do |example|
        ClimateControl.modify action: 'extend_open_enrollment', effective_date: start_on.strftime("%m/%d/%Y"), oe_end_date: start_on.prev_day.strftime("%m/%d/%Y") do
          example.run
        end
      end

      it "should extend open enrollment from enrollment ineligible" do
        expect(ineligible_benefit_application.aasm_state).to eq :enrollment_ineligible
        subject.migrate
        ineligible_benefit_application.reload
        benefit_sponsorship.reload
        expect(ineligible_benefit_application.open_enrollment_period.max).to eq start_on.prev_day
        expect(ineligible_benefit_application.aasm_state).to eq :enrollment_extended
      end

      it "should extend open enrollment from enrollment open" do
        ineligible_benefit_application.update_attributes!(aasm_state: "enrollment_open")
        expect(ineligible_benefit_application.aasm_state).to eq :enrollment_open
        subject.migrate
        ineligible_benefit_application.reload
        benefit_sponsorship.reload
        expect(ineligible_benefit_application.open_enrollment_period.max).to eq start_on.prev_day
        expect(ineligible_benefit_application.aasm_state).to eq :enrollment_extended
      end

      it "should not extend open enrollment from draft" do
        ineligible_benefit_application.update_attributes!(aasm_state: "draft")
        expect(ineligible_benefit_application.aasm_state).to eq :draft
        expect { subject.migrate }.to raise_error("Unable to find benefit application!!")
      end
    end

    context "Update assm state to enrollment open" do
      context "update aasm state to enrollment open for non renewing ER" do
        let(:effective_date) { start_on }

        around do |example|
          ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'begin_open_enrollment' do
            example.run
          end
        end

        it "should update the benefit application" do
          benefit_application.update_attributes!(aasm_state: "enrollment_ineligible", benefit_packages: [])
          # benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_ineligible")
          expect(benefit_application.aasm_state).to eq :enrollment_ineligible
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
          subject.migrate
          benefit_application.reload
          benefit_sponsorship.reload
          expect(benefit_application.aasm_state).to eq :enrollment_open
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
        end

        it "should not update the benefit application" do
          expect { subject.migrate }.to raise_error(RuntimeError)
          expect { subject.migrate }.to raise_error("FAILED: Unable to find application or application is in invalid state")
        end
      end

      context "update aasm state to enrollment open but not sponsoship for renewing ER" do
        let(:effective_date) { start_on }

        around do |example|
          ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'begin_open_enrollment' do
            example.run
          end
        end

        it "should update the benefit application" do
          benefit_application.update_attributes!(aasm_state: :enrollment_ineligible, benefit_packages: [])
          # benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_ineligible")
          expect(benefit_application.aasm_state).to eq :enrollment_ineligible
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
          subject.migrate
          benefit_application.reload
          benefit_sponsorship.reload
          expect(benefit_application.aasm_state).to eq :enrollment_open
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
        end
      end
    end

    context "terminate benefit application" do
      let!(:termination_date) { start_on.next_month.next_day }
      let!(:end_on)           { start_on.next_month.end_of_month }

      around do |example|
        ClimateControl.modify(
            off_cycle_renewal: 'true',
            termination_notice: 'true',
            termination_kind: 'voluntary',
            termination_reason: 'Company went out of business/bankrupt',
            notify_trading_partner: 'true',
            action: 'terminate',
            termination_date: termination_date.strftime("%m/%d/%Y"),
            end_on: end_on.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should terminate the benefit application" do
        subject.migrate
        benefit_application.reload
        expect(benefit_application.aasm_state).to eq :terminated
      end

      it "should transition benefit sponsorship to applicant" do
        subject.migrate
        benefit_sponsorship.reload
        expect(benefit_sponsorship.aasm_state).to eq :applicant
      end

      it "should update end on date on benefit application" do
        subject.migrate
        benefit_application.reload
        expect(benefit_application.end_on).to eq end_on
      end

      it "should update end on date on benefit application" do
        subject.migrate
        benefit_application.reload
        expect(benefit_application.terminated_on).to eq termination_date
      end

      it "should update the termination kind" do
        subject.migrate
        benefit_application.reload
        expect(benefit_application.termination_kind).to eq "voluntary"
      end

      it "should update the termination reason" do
        subject.migrate
        benefit_application.reload
        expect(benefit_application.termination_reason).to eq "Company went out of business/bankrupt"
      end

      it "should terminate any active employee enrollments" do
        subject.migrate
        benefit_application.reload
        benefit_application.hbx_enrollments.each { |hbx_enrollment| expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"}
      end

      it "should terminate any active employee enrollments with termination date as on Benefit Application" do
        subject.migrate
        benefit_application.reload
        benefit_application.hbx_enrollments.each { |hbx_enrollment| expect(hbx_enrollment.terminated_on).to eq end_on }
      end
    end

    context "cancel benefit application", dbclean: :after_each do
      let(:past_start_on) { Date.new(current_effective_date.year, 10, 1) }
      let(:start_on)  { past_start_on }

      let!(:past_effective_period) {past_start_on..past_start_on.next_year.prev_day }
      let!(:mid_plan_year_effective_date) { Date.new(current_effective_date.year, 9, 1) }
      let!(:range_effective_period) { mid_plan_year_effective_date..mid_plan_year_effective_date.next_year.prev_day }
      let(:draft_benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: past_effective_period)
        application.benefit_sponsor_catalog.save!
        application.save
        application

      }

      let!(:import_draft_benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: range_effective_period)
        application.benefit_sponsor_catalog.save!
        application.save
        application
      }

      around do |example|
        ClimateControl.modify plan_year_start_on: range_effective_period.min.strftime("%m/%d/%Y"), action: 'cancel',notify_trading_partner: 'true' do
          example.run
        end
      end

      it "does not cancel non-imported draft benefit applications" do
        benefit_sponsorship.reload
        subject.migrate
        expect(draft_benefit_application.reload.aasm_state).to eq :imported
      end

      it "cancels import draft benefit applications" do
        benefit_sponsorship.reload
        subject.migrate
        expect(import_draft_benefit_application.reload.aasm_state).to eq :canceled
      end
    end

    context "Should update effective period and approve initial benefit application", dbclean: :after_each do
      let(:effective_date)   { Date.new(current_effective_date.year, 10, 1) }
      let(:new_start_date)   { effective_date.next_month }
      let(:new_end_date)     { new_start_date + 1.year }
      let(:effective_period) { effective_date..effective_date.next_year.prev_day }

      let(:benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
        application.benefit_sponsor_catalog.save!
        application
      }

      around do |example|
        ClimateControl.modify(
            action: 'update_effective_period_and_approve',
            effective_date: effective_date.strftime("%m/%d/%Y"),
            new_start_date: new_start_date.strftime("%m/%d/%Y"),
            new_end_date: new_end_date.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should update the initial benefit application and transition the benefit sponsorship" do
        benefit_application.update_attributes!(aasm_state: "draft")
        expect(benefit_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        benefit_application.reload
        benefit_sponsorship.reload
        expect(benefit_application.start_on.to_date).to eq new_start_date
        expect(benefit_application.end_on.to_date).to eq new_end_date
        expect(benefit_application.aasm_state).to eq :approved
        expect(benefit_application.benefit_sponsorship.aasm_state).to eq :applicant
      end

      it "should not update the initial benefit application" do
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("No benefit application found.")
      end
    end

    context "Should force publish the benefit application", dbclean: :after_each do
      let(:effective_date) { start_on }

      around do |example|
        ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'force_submit_application' do
          example.run
        end
      end

      it "should update the benefit application and transition the benefit sponsorship" do
        benefit_application.update_attributes!(aasm_state: "draft")
        expect(benefit_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        benefit_application.reload
        benefit_sponsorship.reload
        expect(benefit_application.effective_period.min.to_date).to eq effective_date
        expect(benefit_application.aasm_state).to eq :enrollment_open
        expect(benefit_application.benefit_sponsorship.aasm_state).to eq :applicant
      end

      it "should not update the benefit application" do
        benefit_sponsorship.benefit_applications.delete_all
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("Found 0 benefit applications with that start date")
      end
    end


    context "Should update effective period and approve renewing benefit application", dbclean: :after_each do
      let(:effective_date) {start_on.next_month.beginning_of_month}
      let(:new_start_date) { (start_on + 2.months).beginning_of_month}
      let(:new_end_date) { new_start_date + 1.year }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:renewing_benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: ((current_effective_date.beginning_of_year)-1.year..(current_effective_date.end_of_year)-1.year))
                                          }
      let(:benefit_market)      { site.benefit_markets.first }
      let!(:product_package_1) { benefit_market_catalog.product_packages.first }
      let!(:product_package_2) { renewing_benefit_market_catalog.product_packages.first }

      let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
      let!(:security_question)  { FactoryGirl.create_default :security_question }

      let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
      let(:benefit_sponsorship) do
        FactoryGirl.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: site.benefit_markets[0],
          employer_attestation: employer_attestation)
      end

      let(:old_effective_period)  { start_on.next_month.beginning_of_month - 1.year ..start_on.end_of_month }
      let!(:old_benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: old_effective_period, aasm_state: :active)
        application.benefit_sponsor_catalog.save!
        application
      }

      let(:renewing_effective_period)  { start_on.next_month.beginning_of_month..start_on.end_of_month + 1.year }
      let!(:renewing_benefit_application) {
        unless benefit_market.benefit_market_catalogs.map(&:product_active_year).include?(new_start_date.year)
          create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                 benefit_market: benefit_market,
                 title: "SHOP Benefits for #{effective_date.year}",
                 application_period: (new_start_date.beginning_of_year..new_start_date.end_of_year))

        end
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: renewing_effective_period, aasm_state: :renewing_enrolling, predecessor_id: old_benefit_application.id)
        application.benefit_sponsor_catalog.save!
        application
      }

      let!(:old_benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: old_benefit_application, product_package: product_package_1) }
      let!(:renewing_benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: renewing_benefit_application, product_package: product_package_2) }

      around do |example|
        ClimateControl.modify(
            action: 'update_effective_period_and_approve',
            effective_date: effective_date.strftime("%m/%d/%Y"),
            new_start_date: new_start_date.strftime("%m/%d/%Y"),
            new_end_date: new_end_date.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should update the renewing benefit application and transition the benefit sponsorship" do
        renewing_benefit_application.update_attributes!(aasm_state: "draft")
        expect(renewing_benefit_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        renewing_benefit_application.reload
        benefit_sponsorship.reload
        expect(renewing_benefit_application.start_on.to_date).to eq new_start_date
        expect(renewing_benefit_application.end_on.to_date).to eq new_end_date
        expect(renewing_benefit_application.aasm_state).to eq :approved
        expect(renewing_benefit_application.benefit_sponsorship.aasm_state).to eq :active
      end
      it "should not update the renewing benefit application" do
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("No benefit application found.")
      end
    end

    context "should trigger termination notice", dbclean: :after_each do

      let(:termination_date) { start_on.next_month.next_day }
      let(:end_on)           { start_on.next_month.end_of_month }

      around do |example|
        ClimateControl.modify(
            off_cycle_renewal: 'true',
            termination_notice: 'true',
            termination_kind: 'voluntary',
            termination_reason: 'Company went out of business/bankrupt',
            notify_trading_partner: 'true',
            action: 'terminate',
            termination_date: termination_date.strftime("%m/%d/%Y"),
            end_on: end_on.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      let(:model_instance) { benefit_application }

      context "should trigger termination notice to employer and employees" do
        it "should trigger model event" do
          model_instance.class.observer_peers.keys.each do |observer|
            expect(observer).to receive(:notifications_send) do |instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :group_advance_termination_confirmation, :klass_instance => model_instance, :options => {})
            end
          end
          subject.migrate
        end
      end
    end
  end
end
