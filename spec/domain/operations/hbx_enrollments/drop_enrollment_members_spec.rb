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

    before :each do
      EnrollRegistry[:drop_enrollment_members].feature.stub(:is_enabled).and_return(true)
    end

    context 'invalid params', dbclean: :around_each do
      context 'when feature is turned off' do
        before do
          EnrollRegistry[:drop_enrollment_members].feature.stub(:is_enabled).and_return(false)
          @result = subject.call({hbx_enrollment: enrollment,
                                  options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                            "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
        end

        it 'should return a failure' do
          expect(@result.failure).to eq "Member drop feature is turned off."
        end
      end

      context 'when sending invalid params' do
        it 'should return a failure when hbx_enrollment key is not present' do
          result = subject.call({options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
          expect(result.failure).to eq "Missing HbxEnrollment Key."
        end

        it 'should return a failure when hbx_enrollment key is not hbx enrollment object' do
          result = subject.call({hbx_enrollment: double,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
          expect(result.failure).to eq "Not a valid HbxEnrollment object."
        end

        it 'should return a failure when hbx_enrollment is not terminatable' do
          allow(enrollment).to receive(:is_admin_terminate_eligible?).and_return(false)
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Enrollment need be in an active state to drop dependent"
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          allow(enrollment).to receive(:is_ivl_by_kind?).and_return(false)
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Not an ivl enrollment."
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s}})

          expect(result.failure).to eq "No members selected to drop."
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "No termination date given."
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => enrollment.effective_on.end_of_year.to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Select termination date that would result member drop in present calender year."
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => enrollment.effective_on.next_year.to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Termination date cannot be outside of the current calender year."
        end

      end
    end

    context 'when members are selected for drop', dbclean: :around_each do
      context 'when previous enrollment has 0 applied aptc' do
        allow(enrollment).to receive(:is_health_enrollment?).and_return(true)
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

        context 'when address not in rating area' do
          before :each do
            enrollment.update_attributes(aasm_state: 'coverage_selected')
            allow(::BenefitMarkets::Locations::RatingArea).to receive(:rating_area_for).with(enrollment.consumer_role.rating_address, during: (TimeKeeper.date_of_record + 2.day)).and_return(nil)
          end

          it 'should return failure' do
            result = subject.call({hbx_enrollment: enrollment,
                                   options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                             "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
            expect(result.failure).to eq 'Rating area could be found.'
          end
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
          expect(new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [new_enrollment.effective_on, enrollment.hbx_enrollment_members.first.eligibility_date]
        end
      end

      context 'when previous enrollment has applied aptc', dbclean: :around_each do
        let(:enrollment_2) do
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
        end

        let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual) }
        let(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_starting_on: enrollment_2.effective_on, effective_ending_on: nil) }


        before do
          enrollment_2.benefit_sponsorship = benefit_sponsorship
          enrollment_2.save!
          product.premium_tables.first.update_attributes!(rating_area: ::BenefitMarkets::Locations::RatingArea.where('active_year' => TimeKeeper.date_of_record.year).first)
          BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
          enrollment_2.update_attributes!(product: product, consumer_role: person.consumer_role)

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

        it 'family should have new enrollment with same product id' do
          reinstatement = family.hbx_enrollments.where(:id.ne => enrollment.id).last
          expect(reinstatement.product.id).to eq enrollment_2.product.id
        end

        context 'when csr kind is different from base enrollment', dbclean: :around_each do
          before :each do
            enrollment_2.update_attributes(aasm_state: 'coverage_selected')
            allow(tax_household).to receive(:eligibile_csr_kind).with(enrollment_2.hbx_enrollment_members.map(&:applicant_id) - [hbx_enrollment_member3.applicant_id]).and_return('csr_100')
          end

          it 'should return failure with new csr variant and product is not available.' do
            result = subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
            expect(result.failure).to eq "Could not find product for new enrollment with present csr kind."
          end

          context 'when the new csr product is available' do
            let(:product_1) {product.dup}

            before :each do
              enrollment_2.update_attributes(aasm_state: 'coverage_selected')
              product_1.update_attributes(hios_id: "#{product.hios_base_id}-02", csr_variant_id: "02")
            end

            it 'enrollment with new product' do
              subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                    "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

              reinstatement = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
              expect(reinstatement.product.id).to eq product_1.id
            end

            it 'when product is not in service area' do
              product_1.unset(:service_area_id)
              result = subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                             "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
              expect(result.failure).to eq "Product is NOT offered in service area."
            end
          end
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

    context 'when subscriber is being dropped' do
      before do
        subject.call({hbx_enrollment: enrollment, options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                                            "terminate_member_#{hbx_enrollment_member3.id}" => enrollment.subscriber.id.to_s}})
        @new_enrollment = family.hbx_enrollments.where(:id.ne => enrollment.id).last
      end

      it 'should have new subscriber' do
        expect(@new_enrollment.subscriber).not_to eq nil
        expect(@new_enrollment.subscriber).not_to eq enrollment.subscriber
      end

      it 'should have new hbx signature' do
        expect(@new_enrollment.enrollment_signature).not_to eq enrollment.enrollment_signature
      end

      it 'should have new consumer role id' do
        expect(@new_enrollment.consumer_role_id).not_to eq nil
        expect(@new_enrollment.consumer_role_id).not_to eq enrollment.consumer_role_id
      end

      it 'should have new consumer role id' do
        expect(@new_enrollment.consumer_role_id).not_to eq nil
        expect(@new_enrollment.consumer_role_id).not_to eq enrollment.consumer_role_id
      end

      it 'all the enr members should have same coverage and eligibility date as new effective date' do
        expect(@new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [@new_enrollment.effective_on]
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
