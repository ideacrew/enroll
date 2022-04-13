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

    let!(:person) { FactoryBot.create(:person, :with_consumer_role)}
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
    let(:consumer_role) { FactoryBot.create(:consumer_role) }

    let!(:enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         :with_product,
                                         family: family,
                                         household: family.active_household,
                                         hbx_enrollment_members: [hbx_enrollment_member1, hbx_enrollment_member2, hbx_enrollment_member3],
                                         aasm_state: "coverage_selected",
                                         kind: "individual",
                                         effective_on: TimeKeeper.date_of_record,
                                         rating_area_id: initial_application.recorded_rating_area_id,
                                         sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                                         sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                         benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                                         consumer_role_id: consumer_role.id)
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    end

    context 'when members are selected for drop', dbclean: :around_each do
      context 'when previous enrollment has 0 applied aptc' do
        before do
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.hbx_id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record + 1.day
        end

        it 'should terminate previously existing enrollment' do
          expect(enrollment.aasm_state).to eq 'coverage_terminated'
        end

        it 'should select coverage for the reinstatement' do
          expect(family.hbx_enrollments.where(:id.ne => enrollment.id).last.aasm_state).to eq 'coverage_selected'
        end
      end

      context 'when termination date is equal to base enrollment effective date' do
        before do
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should cancel previously existing enrollment' do
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
          expect(enrollment.aasm_state).to eq 'coverage_canceled'
        end

        it 'member should have coverage start on as new enrollment effective on' do
          new_enrollment = family.hbx_enrollments.where(:id.ne => enrollment.id).last
          expect(new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [new_enrollment.effective_on]
        end
      end

      context 'when previous enrollment has applied aptc', dbclean: :around_each do
        before do
          enrollment_2 = FactoryBot.create(:hbx_enrollment,
                                           :with_product,
                                           :individual_assisted,
                                           family: family,
                                           household: family.active_household,
                                           hbx_enrollment_members: [hbx_enrollment_member1, hbx_enrollment_member2, hbx_enrollment_member3],
                                           aasm_state: "coverage_selected",
                                           effective_on: TimeKeeper.date_of_record,
                                           applied_aptc_amount: 200,
                                           elected_aptc_pct: 1.0,
                                           rating_area_id: initial_application.recorded_rating_area_id,
                                           sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                                           sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                           benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                                           kind: "individual",
                                           consumer_role_id: consumer_role.id)
          enrollment_2.benefit_sponsorship = benefit_sponsorship
          enrollment_2.save!

          @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual)
          @product.premium_tables.first.update_attributes!(rating_area: ::BenefitMarkets::Locations::RatingArea.where('active_year' => TimeKeeper.date_of_record.year).first)
          BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!

          enrollment_2.update_attributes!(product: @product, consumer_role: person.consumer_role)
          tax_household = FactoryBot.create(:tax_household, household: family.active_household, effective_starting_on: enrollment_2.effective_on, effective_ending_on: nil)
          family.family_members.each do |member|
            FactoryBot.create(:tax_household_member, tax_household: tax_household, applicant_id: member.id)
          end
          enrollment.update_attributes(product_id: enrollment_2.product.id)
          FactoryBot.create(:eligibility_determination, tax_household: tax_household)
          @dropped_members = subject.call({hbx_enrollment: enrollment_2,
                                           options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.hbx_id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
        end

        it 'should recalculate aptc for reinstated enrollment' do
          reinstatement = family.hbx_enrollments.where(:id.ne => enrollment.id).last
          expect(reinstatement.elected_aptc_pct).to_not eq 0.0 #Since there will be a change to coverage_start on member level to new effective date.
          expect(reinstatement.applied_aptc_amount).to_not eq 0
          expect(reinstatement.aggregate_aptc_amount).to_not eq 0
        end
      end

      context 'when termination date is in the past' do
        before do
          FactoryBot.create(:tax_household, household: family.active_household, effective_starting_on: enrollment.effective_on)
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record - 30.days).to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.hbx_id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record - 30.days
        end

        it 'should begin coverage for the reinstatement' do
          expect(family.hbx_enrollments.where(:id.ne => enrollment.id).last.aasm_state).to eq 'coverage_selected'
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
