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

    describe '#eligible_enrollment_members' do
      let(:ivl_benefit) { double('BenefitPackage', residency_status: ['any']) }

      subject do
        enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
        enrollment_renewal.enrollment = input_enrollment
        enrollment_renewal.assisted = assisted
        enrollment_renewal.aptc_values = aptc_values
        enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
        enrollment_renewal
      end

      before do
        allow(subject).to receive(:ivl_benefit).and_return(ivl_benefit)
      end

      context 'members with resident_role' do
        let(:input_enrollment) { enrollment }
      end

      context 'members with consumer_role' do
        let(:input_enrollment) { enrollment }

        context 'when a member is not applying coverage' do
          let(:person_child3) { FactoryBot.create(:person, dob: child3_dob) }
          let!(:consumer_role) { FactoryBot.create(:consumer_role, is_applying_coverage: false, person: person_child3) }

          it 'returns enrollment without member not applying for coverage' do
            expect(
              subject.eligible_enrollment_members.map(&:applicant_id)
            ).not_to include(child3.id)
          end
        end

        context 'when a member is incarcerated' do
          let(:person_child3) { FactoryBot.create(:person, :with_consumer_role, dob: child3_dob, is_incarcerated: true) }

          it 'returns enrollment without incarcerated member' do
            expect(
              subject.eligible_enrollment_members.map(&:applicant_id)
            ).not_to include(child3.id)
          end
        end

        # Valid Citizenship Statuses: us_citizen, naturalized_citizen, indian_tribe_member, alien_lawfully_present, lawful_permanent_resident
        context 'when a member does not have valid citizenship' do
          let(:person3_citizen_status) { ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.sample }
          let(:person_child3) { FactoryBot.create(:person, dob: child3_dob) }
          let!(:consumer_role) { FactoryBot.create(:consumer_role, person: person_child3, citizen_status: person3_citizen_status) }

          it 'returns enrollment without the ineligible citizen' do
            expect(
              subject.eligible_enrollment_members.map(&:applicant_id)
            ).not_to include(child3.id)
          end
        end

        context 'when the members have invalid residency status' do
          let(:child1_dob) { current_date - 6.years }
          let(:child2_dob) { current_date - 3.years }
          let(:child3_dob) { current_date - 2.years }

          let(:ivl_benefit) { double('BenefitPackage', residency_status: ['state_resident']) }

          context 'when all adults are ineligible for residency' do
            let(:primary) do
              per = FactoryBot.create(:person, :with_consumer_role, dob: primary_dob, is_homeless: false, is_temporarily_out_of_state: false)
              per.addresses.update_all(state: 'NV')
              per
            end

            let(:spouse_person) do
              per = FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, is_homeless: false, is_temporarily_out_of_state: false)
              per.addresses.update_all(state: 'NV')
              per
            end

            it 'returns enrollment without the member who is not eligible for residency' do
              expect(
                subject.eligible_enrollment_members.map(&:applicant_id)
              ).not_to include(spouse_person.id)
            end
          end
        end

        context 'when a member has valid residency status' do
          let(:ivl_benefit) { double('BenefitPackage', residency_status: ['state_resident']) }

          context 'when member is homeless' do
            let(:person_child3) { FactoryBot.create(:person, :with_consumer_role, dob: child3_dob, is_homeless: true) }

            it 'returns enrollment with the homeless member' do
              expect(
                subject.eligible_enrollment_members.map(&:applicant_id)
              ).to include(child3.id)
            end
          end

          context 'when member is temporarily out of state' do
            let(:person_child3) { FactoryBot.create(:person, :with_consumer_role, dob: child3_dob, is_temporarily_out_of_state: true) }

            it 'returns enrollment with the member who is temporarily out of state' do
              expect(
                subject.eligible_enrollment_members.map(&:applicant_id)
              ).to include(child3.id)
            end
          end

          context 'when adults are eligible for residency' do
            let(:person_child2) do
              per = FactoryBot.create(:person, :with_consumer_role, dob: child2_dob, is_homeless: false, is_temporarily_out_of_state: false)
              per.addresses.update_all(state: 'NV')
              per
            end

            let(:person_child3) { FactoryBot.create(:person, :with_consumer_role, dob: child3_dob, is_temporarily_out_of_state: true) }

            it 'returns enrollment with the member who is not eligible for residency' do
              expect(
                subject.eligible_enrollment_members.map(&:applicant_id)
              ).to include(child2.id)
            end
          end
        end
      end
    end

    describe '#ivl_benefit' do
      let(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
      let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
      let(:renewal_coverage_start) { Date.new(benefit_package.effective_year) }

      subject do
        enrollment_renewal = described_class.new
        enrollment_renewal.enrollment = double('Enrollment', coverage_kind: 'health')
        enrollment_renewal.renewal_coverage_start = renewal_coverage_start
        enrollment_renewal
      end

      context 'when matching ivl benefit package exists' do
        it 'returns ivl benefit package' do
          expect(subject.ivl_benefit).to be_a(BenefitPackage)
        end
      end
    end

    describe '#slcsp_feature_enabled?' do
      let(:renewal_year) { TimeKeeper.date_of_record.year }

      before do
        EnrollRegistry[
          :atleast_one_silver_plan_donot_cover_pediatric_dental_cost
        ].feature.stub(:is_enabled).and_return(feature_enabled)

        EnrollRegistry[
          :atleast_one_silver_plan_donot_cover_pediatric_dental_cost
        ].settings(renewal_year.to_s.to_sym).stub(:item).and_return(feature_enabled)
      end

      context 'when feature is enabled' do
        let(:feature_enabled) { true }

        it 'returns true' do
          expect(subject.slcsp_feature_enabled?(renewal_year)).to be_truthy
        end
      end

      context 'when feature is disabled' do
        let(:feature_enabled) { false }

        it 'returns false' do
          expect(subject.slcsp_feature_enabled?(renewal_year)).to be_falsey
        end
      end
    end

    describe '.new' do
      context 'logger file' do
        it 'creates logger' do
          subject

          expect(
            File.exist?("#{Rails.root}/log/family_enrollment_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          ).to be_truthy
        end
      end
    end

    describe '#subscriber_dropped?' do
      before do
        allow(
          EnrollRegistry[:generate_initial_enrollment_on_subscriber_drop].feature
        ).to receive(:is_enabled).and_return(feature_enabled)
      end

      let(:fer_instance) do
        subject.enrollment = enrollment
        subject
      end

      let(:renew_enrollment) do
        double(
          'HbxEnrollment',
          hbx_enrollment_members: [
            double('HbxEnrollmentMember', applicant_id: renewal_applicant_id)
          ]
        )
      end

      let(:enrollment) do
        double(
          'HbxEnrollment', subscriber: double(
            'HbxEnrollmentMember', applicant_id: subscriber_applicant_id
          )
        )
      end

      context 'when feature is disabled' do
        let(:feature_enabled) { false }
        let(:renewal_applicant_id) { '11111' }
        let(:subscriber_applicant_id) { '11111' }

        it 'returns false' do
          expect(
            fer_instance.subscriber_dropped?(renew_enrollment)
          ).to be_falsey
        end
      end

      context 'when feature is enabled and subscriber is not dropped' do
        let(:feature_enabled) { true }
        let(:renewal_applicant_id) { '11111' }
        let(:subscriber_applicant_id) { '11111' }

        it 'returns false' do
          expect(
            fer_instance.subscriber_dropped?(renew_enrollment)
          ).to be_falsey
        end
      end

      context 'when feature is enabled and subscriber is dropped' do
        let(:feature_enabled) { true }
        let(:renewal_applicant_id) { '22222' }
        let(:subscriber_applicant_id) { '11111' }

        it 'returns true' do
          expect(
            fer_instance.subscriber_dropped?(renew_enrollment)
          ).to be_truthy
        end
      end
    end

    describe '#eligible_to_get_covered?' do
      before do
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(2023, 11, 1))
        date = TimeKeeper.date_of_record
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:atleast_one_silver_plan_donot_cover_pediatric_dental_cost).and_return(true)
        allow(EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost].settings(date.next_year.year.to_s.to_sym)).to receive(:item).and_return(true)
        allow(enrollment_renewal).to receive(:dental_renewal_product).and_return(current_dental_product)
        allow(current_dental_product).to receive(:allows_child_only_offering?).and_return(true)
      end

      let!(:enrollment_renewal){ Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new}
      let(:dob_date) {TimeKeeper.date_of_record - value.years }
      let!(:primary_dob_update) { primary.update_attributes(dob: dob_date) }
      let(:member) do
        en_member = enrollment.hbx_enrollment_members.first
        enrollment.update_attributes(coverage_kind: 'dental', product: current_dental_product)
        en_member.update_attributes(coverage_start_on: TimeKeeper.date_of_record.beginning_of_year)
        en_member
      end

      subject do
        enrollment_renewal.enrollment = enrollment
        enrollment_renewal.assisted = false
        enrollment_renewal.aptc_values = {}
        enrollment_renewal.renewal_coverage_start = TimeKeeper.date_of_record.next_year.beginning_of_year
        enrollment_renewal
      end

      context 'where member age is less than 19 years old' do
        let(:value) { 18 }
        it 'member is not eligible to get covered' do
          expect(subject.eligible_to_get_covered?(member)).to be_truthy
        end
      end

      context 'where member age is 19 years old' do
        let(:value) { 19 }
        it 'member is not eligible to get covered' do
          expect(subject.eligible_to_get_covered?(member)).to be_falsey
        end
      end

      context 'where member age is greater than 19 years old' do
        let(:value) { 20 }
        it 'member is eligible to get covered' do
          expect(subject.eligible_to_get_covered?(member)).to be_truthy
        end
      end
    end

    after :all do
      file_path = "#{Rails.root}/log/family_enrollment_renewal_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      FileUtils.rm_rf(file_path) if File.file?(file_path)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.today)
    end
  end
end
