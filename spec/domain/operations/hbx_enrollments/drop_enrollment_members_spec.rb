# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::HbxEnrollments::DropEnrollmentMembers, :type => :model, dbclean: :around_each do
  describe 'drop enrollment members',  dbclean: :around_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:benefit_package)  { initial_application.benefit_packages.first }
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}

    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_nuclear_family, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }

    let(:hbx_enrollment_member1) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members.first.id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end
    let(:hbx_enrollment_member2) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members.last.id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end
    let(:hbx_enrollment_member3) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members[1].id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end

    let!(:enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         :with_product,
                                         family: family,
                                         household: family.active_household,
                                         hbx_enrollment_members: [hbx_enrollment_member1, hbx_enrollment_member2, hbx_enrollment_member3],
                                         aasm_state: "coverage_selected",
                                         effective_on: initial_application.start_on,
                                         rating_area_id: initial_application.recorded_rating_area_id,
                                         sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                                         sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                         benefit_sponsorship_id: initial_application.benefit_sponsorship.id)
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    end

    context 'when members are selected for drop', dbclean: :around_each do
      context 'when previous enrollment has 0 applied aptc' do
        before do
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
        end

        it 'should terminate previously existing enrollment' do
          expect(enrollment.aasm_state).to eq 'coverage_terminated'
        end
      end

      context 'when previous enrollment has applied aptc' do
        before do
          enrollment.update_attributes!(applied_aptc_amount: 100)
          FactoryBot.create(:tax_household, household: family.active_household, effective_starting_on: enrollment.effective_on)
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
        end
      end
    end

    context 'when members are NOT selected for drop', dbclean: :around_each do
      before do
        @dropped_members = subject.call({hbx_enrollment: enrollment,
                                         options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s}}).failure
      end

      it 'should return dropped member info' do
        expect(@dropped_members).to eq 'No members selected to drop.'
      end

      it 'should not terminate previously existing enrollment' do
        expect(enrollment.aasm_state).to eq 'coverage_selected'
      end
    end

  end
end
