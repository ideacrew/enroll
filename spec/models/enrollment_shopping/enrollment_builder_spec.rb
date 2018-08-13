require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe EnrollmentShopping::EnrollmentBuilder, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup employees with benefits"

  let(:dental_sponsored_benefit) { true }
  let(:roster_size) { 2 }
  let(:start_on) { TimeKeeper.date_of_record.prev_month.beginning_of_month }
  let(:effective_period) { start_on..start_on.next_year.prev_day }

  let(:ce) { benefit_sponsorship.census_employees.non_business_owner.first }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: abc_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }

  let(:person) { family.primary_applicant.person }
  let(:effective_on) { start_on }
  let(:is_qle?) { false }
  let(:family_member_ids) { family.family_members.map(&:id) }
  let(:coverage_household) { family.active_household.immediate_family_coverage_household }
  let(:employee_role) { person.active_employee_roles.first }

  let(:enrollment_builder) { EnrollmentShopping::EnrollmentBuilder.new(coverage_household, employee_role, coverage_kind) }

  describe ".build_new_enrollment" do

    context "when employee shopping" do

      let(:coverage_kind) { 'dental' }

      context "under open enrollment period, built dental enrollment" do

        let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:open_enrollment_start_on) { TimeKeeper.date_of_record }
        let(:aasm_state) { :enrollment_open }

        subject(:dental_enrollment) { enrollment_builder.build_new_enrollment(family_member_ids: family_member_ids, is_qle: is_qle?, optional_effective_on: effective_on) }

        it "should build a new dental enrollment" do
          expect(dental_enrollment.valid?).to be_truthy
          expect(dental_enrollment.coverage_kind).to eq 'dental'
          expect(dental_enrollment.effective_on).to eq effective_on
          expect(dental_enrollment.enrollment_kind).to eq 'open_enrollment'
          expect(dental_enrollment.hbx_enrollment_members).to be_present
          expect(dental_enrollment.benefit_sponsorship).to eq benefit_sponsorship
          expect(dental_enrollment.sponsored_benefit_package).to eq current_benefit_package
          expect(dental_enrollment.sponsored_benefit).to eq current_benefit_package.sponsored_benefit_for(coverage_kind)
        end
      end

      context "under new hire enrollment period" do

        context "with past hired on date" do

          let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
          let(:aasm_state) { :active }

          let!(:ce) { 
            census_employee = benefit_sponsorship.census_employees.non_business_owner.first
            census_employee.update(hired_on: TimeKeeper.date_of_record - 2.years)
            census_employee
          } 

          subject(:dental_enrollment) { enrollment_builder.build_new_enrollment(family_member_ids: family_member_ids, is_qle: false, optional_effective_on: nil) }

          it "should build a new dental enrollment with effective date same as plan year start date" do
            expect(dental_enrollment.valid?).to be_truthy
            expect(dental_enrollment.coverage_kind).to eq 'dental'
            expect(dental_enrollment.effective_on).to eq start_on
            expect(dental_enrollment.enrollment_kind).to eq 'open_enrollment'
            expect(dental_enrollment.hbx_enrollment_members).to be_present
            expect(dental_enrollment.benefit_sponsorship).to eq benefit_sponsorship
            expect(dental_enrollment.sponsored_benefit_package).to eq current_benefit_package
            expect(dental_enrollment.sponsored_benefit).to eq current_benefit_package.sponsored_benefit_for(coverage_kind)
          end
        end

        context "with current hired on date" do 
          let(:hired_on) { TimeKeeper.date_of_record - 2.days }

          let(:earliest_effective_on) { 
            hired_on.mday == 1 ? hired_on : hired_on.next_month.beginning_of_month
          }

          let!(:ce) { 
            census_employee = benefit_sponsorship.census_employees.non_business_owner.first
            census_employee.update(hired_on: hired_on)
            census_employee
          } 

          subject(:dental_enrollment) { enrollment_builder.build_new_enrollment(family_member_ids: family_member_ids, is_qle: false, optional_effective_on: nil) }

          it "should build a new dental enrollment with effective date beginning of next month" do
            expect(dental_enrollment.valid?).to be_truthy
            expect(dental_enrollment.coverage_kind).to eq 'dental'
            expect(dental_enrollment.effective_on).to eq earliest_effective_on
            expect(dental_enrollment.enrollment_kind).to eq 'open_enrollment'
            expect(dental_enrollment.hbx_enrollment_members).to be_present
            expect(dental_enrollment.benefit_sponsorship).to eq benefit_sponsorship
            expect(dental_enrollment.sponsored_benefit_package).to eq current_benefit_package
            expect(dental_enrollment.sponsored_benefit).to eq current_benefit_package.sponsored_benefit_for(coverage_kind)
          end
        end
      end

      context "under special enrollment period" do

        let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
        let(:aasm_state) { :active }
        let(:qualifying_life_event_kind) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
        let(:qle_on) { TimeKeeper.date_of_record - 2.days }

        let!(:special_enrollment_period) {
          special_enrollment = family.special_enrollment_periods.build({
            qle_on: qle_on,
            effective_on_kind: "date_of_event",
            })

          special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
          special_enrollment.save!
          special_enrollment
        }

        subject(:dental_enrollment) { enrollment_builder.build_new_enrollment(family_member_ids: family_member_ids, is_qle: true, optional_effective_on: nil) }

        it "should build a new SEP dental enrollment with effective date matching QLE on date" do
          expect(dental_enrollment.valid?).to be_truthy
          expect(dental_enrollment.coverage_kind).to eq 'dental'
          expect(dental_enrollment.effective_on).to eq qle_on
          expect(dental_enrollment.enrollment_kind).to eq 'special_enrollment'
          expect(dental_enrollment.hbx_enrollment_members).to be_present
          expect(dental_enrollment.benefit_sponsorship).to eq benefit_sponsorship
          expect(dental_enrollment.sponsored_benefit_package).to eq current_benefit_package
          expect(dental_enrollment.sponsored_benefit).to eq current_benefit_package.sponsored_benefit_for(coverage_kind)
        end
      end
    end
  end

  describe ".build_change_enrollment" do
    context "when employee making changes to dental coverage" do
      context "during open enrollment period" do
        it "should change dental enrollmet" do
        end
      end

      context "during new hire enrollment period" do
        it "should change dental enrollmet" do
        end
      end

      context "during special enrollment period" do
        it "should change dental enrollmet" do
        end
      end
    end 
  end
end