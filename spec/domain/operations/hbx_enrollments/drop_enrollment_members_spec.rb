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

    let(:product2) { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual) }
    let!(:enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         product: product2,
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

      context 'when retro active feature is turned off && termination date is past date' do
        before do
          @result = subject.call({hbx_enrollment: enrollment,
                                  options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record - 1.day).to_s,
                                            "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
        end

        it 'should return a failure' do
          expect(@result.failure).to eq "Unable to disenroll member(s) because of retroactive date selection."
        end

        context 'and admin does not have permission to drop members' do
          before do
            @result = subject.call({hbx_enrollment: enrollment,
                                    options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record - 1.day).to_s,
                                              "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                              "admin_permission" => false}})
          end

          it 'should return the admin permission error' do
            expect(@result.failure).to eq "Unable to disenroll member(s). Admin does not have access to use this tool."
          end
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

          expect(result.failure).to eq "Enrollment need be in an active state to drop dependent."
        end

        it 'should return a failure when hbx_enrollment is not an ivl' do
          allow(enrollment).to receive(:is_ivl_by_kind?).and_return(false)
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Not an ivl enrollment."
        end

        it 'should return a failure when members have not been selected for termination' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s}})

          expect(result.failure).to eq "Member(s) have not been selected for termination."
        end

        it 'should return a failure when termination date has not been selected' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Termination date has not been selected."
        end

        context 'when termination date is before effective on' do
          before do
            new_effective_on = Date.today.next_year.beginning_of_year
            enrollment.update(effective_on: new_effective_on)
          end

          it 'should return a failure when termination date is not in current calendar year' do
            termination_date = enrollment.effective_on - 1
            result = subject.call({hbx_enrollment: enrollment,
                                   options: {"termination_date_#{enrollment.id}" => termination_date.to_s,
                                             "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})
            expect(result.failure).to eq "Termination date must be in current calendar year."
          end
        end

        it 'should return a failure when termination date is not in current calendar year' do
          result = subject.call({hbx_enrollment: enrollment,
                                 options: {"termination_date_#{enrollment.id}" => enrollment.effective_on.next_year.to_s,
                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}})

          expect(result.failure).to eq "Termination date cannot be outside of the current calendar year."
        end

      end
    end

    context 'when members are selected for drop', dbclean: :around_each do
      context 'when previous enrollment has 0 applied aptc' do
        before do
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                     "admin_permission" => true}}).success
          allow(enrollment).to receive(:is_health_enrollment?).and_return(true)
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
                                             "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                             "admin_permission" => true}})
            expect(result.failure).to eq 'Rating area could not be found.'
          end
        end
      end

      context 'when termination date is equal to base enrollment effective date' do
        # set the date to a day other than the first of the month to ensure it is not the same as the coverage start on
        let(:non_first_date) {Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, 2)}
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(non_first_date)
          enrollment.update_attributes(effective_on: non_first_date)
          @dropped_members = subject.call({hbx_enrollment: enrollment,
                                           options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                     "admin_permission" => true}}).success
        end

        it 'should cancel previously existing enrollment' do
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
          expect(enrollment.aasm_state).to eq 'coverage_canceled'
        end

        it 'member should have coverage start on as new enrollment effective on' do
          # since checking product hios_id instead of subscriber drop for coverage start on,
          # member's start on will be the coverage_start_on from the old enrollment
          new_enrollment = family.hbx_enrollments.where(:id.ne => enrollment.id).last
          expect(new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [enrollment.effective_on, enrollment.hbx_enrollment_members.first.coverage_start_on]
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
                                                     "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                     "admin_permission" => true}}).success
        end

        it 'should return dropped member info' do
          expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.hbx_id.to_s
          expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
        end

        it 'should recalculate aptc for reinstated enrollment' do
          reinstatement = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
          expect(reinstatement.elected_aptc_pct).to_not eq 0.0 #Since there will be a change to coverage_start on member level to new effective date.
          expect(reinstatement.applied_aptc_amount).to_not eq 0
          expect(reinstatement.aggregate_aptc_amount).to_not eq 0
        end

        it 'family should have new enrollment with same product id' do
          reinstatement = family.hbx_enrollments.where(:id.ne => enrollment.id).last
          expect(reinstatement.product.id).to eq enrollment_2.product.id
        end

        context 'when droping subscriber' do
          it 'new enrollment should have aptc amount ' do
            enrollment_2.update_attributes(aasm_state: 'coverage_selected')
            HbxEnrollment.all.where(:family_id => enrollment_2.family_id, :id.ne => enrollment_2.id).delete
            allow(enrollment_2).to receive(:is_health_enrollment?).and_return(false)
            subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                  "terminate_member_#{hbx_enrollment_member1.id}" => hbx_enrollment_member1.id.to_s,
                                                                  "admin_permission" => true}})
            reinstatement = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
            expect(reinstatement.applied_aptc_amount).not_to eq 0.0
          end

          context 'subscribers birthday is between original coverage_start_on and new enrollment effective_on' do
            before do
              dob = hbx_enrollment_member1.person.dob
              birth_month = (TimeKeeper.date_of_record - 3.months).month
              hbx_enrollment_member1.person.update_attributes!(dob: Date.new(dob.year, birth_month, dob.day))
              hbx_enrollment_member2.person.update_attributes!(dob: Date.new(dob.year, birth_month, dob.day + 1))
              enrollment_2.update_attributes!(effective_on: TimeKeeper.date_of_record - 6.months)
              subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                                                    "terminate_member_#{hbx_enrollment_member3.id}" => enrollment_2.subscriber.id.to_s,
                                                                    "admin_permission" => true}})
              @new_enrollment = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
            end

            it 'should calculate based on original coverage_start_on date' do
              expect(@new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [@new_enrollment.effective_on, enrollment_2.hbx_enrollment_members.first.coverage_start_on].uniq
            end
          end
        end

        context 'when csr kind is different from base enrollment', dbclean: :around_each do
          before :each do
            enrollment_2.update_attributes(aasm_state: 'coverage_selected')
            allow(tax_household).to receive(:eligibile_csr_kind).with(enrollment_2.hbx_enrollment_members.map(&:applicant_id) - [hbx_enrollment_member3.applicant_id]).and_return('csr_100')
          end

          it 'should return failure with new csr variant and product is not available.' do
            result = subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                           "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                                           "admin_permission" => true}})
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
                                                                    "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                                    "admin_permission" => true}})

              reinstatement = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
              expect(reinstatement.product.id).to eq product_1.id
            end

            it 'enrollment with should have older product for dental' do
              allow(enrollment_2).to receive(:is_health_enrollment?).and_return(false)
              subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                    "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                                    "admin_permission" => true}})
              reinstatement = family.hbx_enrollments.where(:id.ne => enrollment_2.id).last
              expect(reinstatement.product.id).not_to eq product_1.id
            end

            it 'when product is not in service area' do
              product_1.unset(:service_area_id)
              result = subject.call({hbx_enrollment: enrollment_2, options: {"termination_date_#{enrollment_2.id}" => TimeKeeper.date_of_record.to_s,
                                                                             "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s,
                                                                             "admin_permission" => true}})
              expect(result.failure).to eq "Product is NOT offered in service area."
            end
          end
        end
      end

      # TODO: Fix this when we allow retro scenarios
      # context 'when termination date is in the past' do
      #   before do
      #     FactoryBot.create(:tax_household, household: family.active_household, effective_starting_on: enrollment.effective_on)
      #     @dropped_members = subject.call({hbx_enrollment: enrollment,
      #                                      options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record - 30.days).to_s,
      #                                                "terminate_member_#{hbx_enrollment_member3.id}" => hbx_enrollment_member3.id.to_s}}).success
      #   end

      #   it 'should return dropped member info' do
      #     expect(@dropped_members.first[:hbx_id]).to eq hbx_enrollment_member3.hbx_id.to_s
      #     expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record - 30.days
      #   end

      #   it 'should begin coverage for the reinstatement' do
      #     expect(family.hbx_enrollments.where(:id.ne => enrollment.id).last.aasm_state).to eq 'coverage_selected'
      #   end
      # end
    end

    context 'when subscriber is being dropped' do
      before do
        subject.call({hbx_enrollment: enrollment, options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record + 1.day).to_s,
                                                            "terminate_member_#{hbx_enrollment_member3.id}" => enrollment.subscriber.id.to_s,
                                                            "admin_permission" => true}})
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

      it 'members coverage start on should be the same as the old enrollment' do
        expect(@new_enrollment.hbx_enrollment_members.pluck(:eligibility_date, :coverage_start_on).flatten.uniq).to eq [@new_enrollment.effective_on, enrollment.hbx_enrollment_members.first.coverage_start_on]
      end
    end

    context 'when members are NOT selected for drop', dbclean: :around_each do
      before do
        @dropped_members = subject.call({hbx_enrollment: enrollment,
                                         options: {"termination_date_#{enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                   "admin_permission" => true}}).failure
      end

      it 'should return dropped member info' do
        expect(@dropped_members).to eq 'Member(s) have not been selected for termination.'
      end

      it 'should not terminate previously existing enrollment' do
        expect(enrollment.aasm_state).to eq 'coverage_selected'
      end
    end

    context 'when passing nil for terminated member with key present' do
      it 'should return failure.' do
        dropped_members = subject.call({hbx_enrollment: enrollment,
                                        options: {"termination_date_#{enrollment.id}" => (TimeKeeper.date_of_record - 30.days).to_s,
                                                  "terminate_member_#{hbx_enrollment_member3.id}" => nil,
                                                  "admin_permission" => true}}).failure
        expect(dropped_members).to eq 'Unable to disenroll member(s) because of retroactive date selection.'
      end
    end
  end

  describe 'when mthh is enabled' do
    before do
      EnrollRegistry[:drop_enrollment_members].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)

      allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
        double('IdentifySlcspWithPediatricDentalCosts',
               call: double(:value! => slcsp_info, :success? => true))
      )
    end

    let(:family) do
      family = FactoryBot.build(:family, person: primary)
      family.family_members = [
        FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent)
      ]

      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent.id, kind: 'spouse')
      family.save
      family
    end

    let(:dependent) { FactoryBot.create(:person, :with_consumer_role) }
    let(:primary) { FactoryBot.create(:person, :with_consumer_role) }
    let(:primary_applicant) { family.primary_applicant }
    let(:dependents) { family.dependents }

    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let!(:inactive_tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let(:tax_household) do
      tax_household_group.tax_households.first
    end

    let(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: family.family_members.map(&:id).map(&:to_s),
        tax_household_id: tax_household.id
      )

      determination
    end

    let(:aptc_grant) { eligibility_determination.grants.first }

    let(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_shopping,
                        :with_silver_health_product,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        family: family,
                        consumer_role_id: primary.consumer_role.id,
                        aasm_state: 'coverage_selected',
                        elected_aptc_pct: 1.0,
                        applied_aptc_amount: 975.0)
    end

    let(:dependent_member) { hbx_enrollment.hbx_enrollment_members[1] }

    let(:yearly_expected_contribution) { 125.00 * 12 }

    let(:slcsp_info) do
      OpenStruct.new(
        households: [OpenStruct.new(
          household_id: aptc_grant.tax_household_id,
          household_benchmark_ehb_premium: benchmark_premium,
          members: family.family_members.collect do |fm|
            OpenStruct.new(
              family_member_id: fm.id.to_s,
              relationship_with_primary: fm.primary_relationship,
              date_of_birth: fm.dob,
              age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
            )
          end
        )]
      )
    end

    let(:primary_bp) { 500.00 }
    let(:dependent_bp) { 600.00 }
    let(:benchmark_premium) { primary_bp }

    it 'recalculates aptc by ignoring dependent benchmark_premium' do
      @dropped_members = subject.call({hbx_enrollment: hbx_enrollment,
                                       options: {"termination_date_#{hbx_enrollment.id}" => TimeKeeper.date_of_record.to_s,
                                                 "terminate_member_#{dependent_member.id}" => dependent_member.id.to_s,
                                                 "admin_permission" => true}}).success
      expect(@dropped_members.first[:hbx_id]).to eq dependent_member.hbx_id.to_s
      expect(@dropped_members.first[:terminated_on]).to eq TimeKeeper.date_of_record
      reinstatement = family.hbx_enrollments.where(:id.ne => hbx_enrollment.id).last
      expect(reinstatement.elected_aptc_pct).to eq 1.0
      expect(reinstatement.aggregate_aptc_amount.to_f).to eq 375.0
    end
  end
end
