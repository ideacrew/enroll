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

  subject { EnrollmentShopping::EnrollmentBuilder.new(coverage_household, employee_role, coverage_kind) }

  describe ".build_new_enrollment" do

    context "when employee shopping for dental coverage" do

      let(:coverage_kind) { 'dental' }

      context "during open enrollment period" do

        let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:open_enrollment_start_on) { TimeKeeper.date_of_record }
        let(:aasm_state) { :enrollment_open }

        it "should build a new dental enrollment" do

          new_enrollment = subject.build_new_enrollment(family_member_ids: family_member_ids, is_qle: is_qle?, optional_effective_on: effective_on)

          expect(new_enrollment.valid?).to be_truthy
          expect(new_enrollment.coverage_kind).to eq 'dental'
          expect(new_enrollment.effective_on).to eq effective_on
          expect(new_enrollment.enrollment_kind).to eq 'open_enrollment'
          expect(new_enrollment.hbx_enrollment_members).to be_present
          expect(new_enrollment.benefit_sponsorship).to eq benefit_sponsorship
          expect(new_enrollment.sponsored_benefit_package).to eq current_benefit_package
          expect(new_enrollment.sponsored_benefit).to eq current_benefit_package.sponsored_benefit_for(coverage_kind)
        end
      end

      context "during new hire enrollment period" do

        it "should build a new dental enrollment" do

        end
      end

      context "during special enrollment period" do

        let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
        let(:aasm_state) { :active }
        let(:qualifying_life_event_kind) { FactoryGirl.create(:qualifying_life_event_kind, ) }

        let(:special_enrollment_period) {
          special_enrollment = shop_family.special_enrollment_periods.build({
            qle_on: qle_date,
            effective_on_kind: "first_of_month",
            })

          special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
          special_enrollment.save!
          special_enrollment
        }
        
        it "should build a new dental enrollment" do

        end
      end
    end
  end


  describe ".build_change_enrollment" do
    context "when employee making changes to dental coverage" do

      context "during open enrollment period" do
        let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:open_enrollment_start_on) { TimeKeeper.date_of_record }
        let(:aasm_state) { :enrollment_open }

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