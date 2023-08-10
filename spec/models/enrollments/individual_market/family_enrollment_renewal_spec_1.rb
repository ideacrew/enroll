# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/family_enrollment_renewal.rb"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Enrollments::IndividualMarket::FamilyEnrollmentRenewal, type: :model, :dbclean => :after_each do
    include FloatHelper
    include_context "setup family initial and renewal enrollments data"

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
    end

    after :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    describe ".eligible_enrollment_members" do
      context "#consumer_role" do
        context "when one of the member is is_incarcerated" do
          let!(:renewal_klass) do
            enrollment.hbx_enrollment_members[1].person.update_attributes!(is_incarcerated: true)
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end

          it "should return 4 eligible members" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 4
          end
        end

        context "when one of the member is is_incarcerated and other is not applying_coverage" do
          let!(:renewal_klass) do
            enrollment.hbx_enrollment_members[1].person.update_attributes!(is_incarcerated: true)
            enrollment.hbx_enrollment_members[2].person.consumer_role.update_attributes!(is_applying_coverage: false)
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end

          it "should return 4 eligible members" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 3
          end
        end

        context "when primary does not have the state address" do
          let!(:renewal_klass) do
            enrollment.hbx_enrollment_members[0].person.addresses.delete_all
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end

          it "should return 0 eligible members" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 0
          end
        end

        context "when one of the member is not lawfully_present" do
          let!(:renewal_klass) do
            consumer_role = enrollment.hbx_enrollment_members[1].person.consumer_role
            consumer_role.lawful_presence_determination.update_attributes!(citizen_status: "not_lawfully_present_in_us")
            enrollment.reload
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end

          it "should return 4 eligible members" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 4
          end
        end
      end

      context "#resident_role" do
        context "when member is not incarcerated" do
          let!(:renewal_klass) do
            coverall_enrollment.hbx_enrollment_members[0].person.update_attributes!(is_incarcerated: false)
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = coverall_enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end
          it "should return 1 eligible member" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 1
          end
        end

        context "when the member is incarcerated" do
          let!(:renewal_klass) do
            coverall_enrollment.hbx_enrollment_members[0].person.update_attributes!(is_incarcerated: true)
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = coverall_enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
            enrollment_renewal
          end
          it "should return 0 eligible members" do
            expect(renewal_klass.eligible_enrollment_members.count).to eq 0
          end
        end
      end
    end
  end

  def update_age_off_excluded(fam, true_or_false)
    fam.family_members.map(&:person).each do |per|
      per.update_attributes!(age_off_excluded: true_or_false)
    end
  end
end
