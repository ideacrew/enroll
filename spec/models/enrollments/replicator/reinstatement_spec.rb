require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Enrollments::Replicator::Reinstatement, :type => :model, dbclean: :around_each do

  describe 'initial employer',  dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record - 3.months }
    let(:employee_created_at) { hired_on }
    let(:employee_updated_at) { employee_created_at }

    let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}


    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

    let(:aasm_state) { :active }
    let(:census_employee) do
      create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: current_benefit_package, hired_on: hired_on,
                                                        created_at: employee_created_at, updated_at: employee_updated_at)
    end
    let!(:family) do
      person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
      census_employee.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    end

    let!(:employee_role){census_employee.employee_role}

    let(:enrollment_kind) { "open_enrollment" }
    let(:special_enrollment_period_id) { "some id" }

    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        household: family.latest_household,
                        coverage_kind: "health",
                        family: family,
                        effective_on: effective_on,
                        enrollment_kind: enrollment_kind,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        special_enrollment_period_id: special_enrollment_period_id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id,
                        product: sponsored_benefit.reference_product,

                        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
    end

    before do
      census_employee.terminate_employment(effective_on + 1.days)
      enrollment.reload
      census_employee.reload
    end

    context 'when enrollment reinstated', dbclean: :around_each do

      let(:reinstated_enrollment) do
        Enrollments::Replicator::Reinstatement.new(enrollment, enrollment.terminated_on.next_day).build
      end

      it "should build reinstated enrollment" do
        expect(reinstated_enrollment.kind).to eq enrollment.kind
        expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should build a continuous coverage' do
        expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
      end

      it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
        enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
        expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end

      it 'reinstated enrollment should have special_enrollment_period_id' do
        expect(reinstated_enrollment.special_enrollment_period_id).to eq special_enrollment_period_id
      end
    end

    context 'when enrollment reinstated for person with tobacco attestation', dbclean: :around_each do
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_tobacco_use_enrollment_members,
                          enrollment_members: covered_individuals,
                          household: family.latest_household,
                          coverage_kind: "health",
                          family: family,
                          effective_on: effective_on,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end
      before do
        enrollment.hbx_enrollment_members.first.family_member.person.update_attributes(is_tobacco_user: 'N')
      end

      it 'Enrollment member has tobacco attestation' do
        reinstated_enrollment = Enrollments::Replicator::Reinstatement.new(enrollment, enrollment.terminated_on.next_day).build
        expect(reinstated_enrollment.hbx_enrollment_members.map(&:tobacco_use).uniq).to eq ['Y']
      end
    end

    context 'future termination date for base enrollment provided', dbclean: :around_each do
      it 'Enrollment member has tobacco attestation' do
        Enrollments::Replicator::Reinstatement.new(enrollment, enrollment.terminated_on.next_day).build
        expect(enrollment.aasm_state).to eq 'coverage_terminated'
      end
    end
  end

  describe "renewing employer",  dbclean: :around_each do
    context "enrollment reinstate effective date" do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      let(:predecessor_application_catalog) { true }
      let(:renewal_state) { :enrollment_open }

      let(:effective_on) { current_effective_date }
      let(:renewal_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let!(:renewal_benefit_package) { renewal_application.benefit_packages.first }
      let!(:renewal_sponsored_benefit) { renewal_benefit_package.health_sponsored_benefit }

      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}


      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.where(aasm_state: :active).first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) do
        sponsored_benefit.product_package_kind = :single_product
        sponsored_benefit.reference_product.renewal_product = renewal_sponsored_benefit.reference_product
        sponsored_benefit.save
        renewal_sponsored_benefit.update_attributes(product_package_kind: :single_product)
        renewal_sponsored_benefit.sponsor_contribution.contribution_levels.each do |level|
          level.contribution_unit_id = renewal_sponsored_benefit.contribution_model.contribution_units.where(display_name: level.display_name).first.id
          level.save
        end
      end

      let(:aasm_state) { :active }
      let(:census_employee) do
        create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: current_benefit_package, hired_on: hired_on,
                                                          created_at: employee_created_at, updated_at: employee_updated_at)
      end
      let!(:family) do
        person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
        employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
        census_employee.update_attributes({employee_role: employee_role})
        Family.find_or_build_from_employee_role(employee_role)
      end

      let!(:employee_role){census_employee.employee_role}

      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { "some id" }


      let(:covered_individuals) { family.family_members }
      let(:person) { family.primary_applicant.person }

      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                          enrollment_members: covered_individuals,
                          household: family.latest_household,
                          coverage_kind: "health",
                          family: family,
                          effective_on: effective_on,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          special_enrollment_period_id: special_enrollment_period_id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      context "prior to renewing plan year begin date" do
        let(:reinstate_effective_date) { renewal_effective_date.prev_month }

        let(:reinstated_enrollment) do
          enrollment.reinstate(edi: false)
        end

        before do
          census_employee.terminate_employment(reinstate_effective_date.prev_day)
          enrollment.reload
          census_employee.reload
        end

        it "should build reinstated enrollment" do
          expect(reinstated_enrollment.kind).to eq enrollment.kind
          expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should build a continuous coverage' do
          expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
          enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
          expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end

        it "should generate passive renewal" do
          initial_benefit_package = renewal_application.predecessor.benefit_packages.first
          renewal_application.benefit_packages.first.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
          reinstated_enrollment
          enrollment = HbxEnrollment.where({ family_id: family.id,
                                             :effective_on => renewal_effective_date,
                                             :aasm_state.ne => 'coverage_canceled'}).first
          expect(enrollment.present?).to be_truthy

          expect(enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.renewal_benefit_application
        end

        it 'reinstated enrollment should have special_enrollment_period_id' do
          expect(reinstated_enrollment.special_enrollment_period_id).to eq special_enrollment_period_id
        end
      end

      context "same as renewing plan year begin date" do
        let(:reinstate_effective_date) { renewal_effective_date }

        context "when plan year is renewing" do
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            enrollment.terminate_coverage!(reinstate_effective_date.prev_day)
            enrollment.reload
            census_employee.reload
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq reinstate_effective_date
            expect(reinstated_enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.renewal_benefit_application
            expect(reinstated_enrollment.product_id).to eq renewal_benefit_package.health_sponsored_benefit.reference_product.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = HbxEnrollment.where({family_id: family.id,
                                              :effective_on => renewal_effective_date,
                                              :aasm_state.ne => 'coverage_canceled'}).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end

        context "when renewal plan year is already active" do
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            TimeKeeper.set_date_of_record_unprotected!(renewal_effective_date + 5.days)
            benefit_sponsorship.benefit_applications.where(aasm_state: :active).first.update(aasm_state: :expired)
            renewal_application.update(aasm_state: :active)
            benefit_sponsorship.reload
            census_employee.benefit_sponsorship.reload
            census_employee.terminate_employment(reinstate_effective_date.prev_day)
            enrollment.reload
            census_employee.reload
          end

          after do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq reinstate_effective_date
            expect(reinstated_enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.active_benefit_application
            expect(reinstated_enrollment.product_id).to eq renewal_benefit_package.health_sponsored_benefit.reference_product.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = HbxEnrollment.where({family_id: family.id,
                                              :effective_on => renewal_effective_date,
                                              :aasm_state.ne => 'coverage_canceled'}).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end
      end
    end
  end

  describe "extract_csr_kind",  dbclean: :around_each do
    let(:person10) {FactoryBot.create(:person, :with_consumer_role)}
    let(:benefit_coverage_period) { BenefitCoveragePeriod.new(start_on: Date.new(Time.current.year,1,1)) }
    let(:c1) {FactoryBot.create(:consumer_role)}
    let(:c2) {FactoryBot.create(:consumer_role)}
    let(:r1) {FactoryBot.create(:resident_role)}
    let(:r2) {FactoryBot.create(:resident_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person10)}
    let(:family_members) { family.family_members.where(is_primary_applicant: false).to_a }
    let(:household) { family.active_household }
    let(:member1) { FactoryBot.build(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, family_member: family.family_members.where(is_primary_applicant: true).first, applicant_id: family.family_members.first.id) }
    let(:member2) {double(person: double(consumer_role: c2),hbx_enrollment: hbx_enrollment,family_member: family.family_members.where(is_primary_applicant: false).first, applicant_id: family.family_members[1].id)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment, kind: "individual", effective_on: TimeKeeper.date_of_record, household: family.latest_household, enrollment_signature: true, family: family, consumer_role_id: person10.consumer_role.id)
      hbx_enrollment_member = FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: true).first.id, hbx_enrollment: enr)
      hbx_enrollment_member1 = FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).first.id, hbx_enrollment: enr)
      enr.hbx_enrollment_members << hbx_enrollment_member << hbx_enrollment_member1
      enr
    end
    let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
    let!(:tax_household_member1) { tax_household.tax_household_members.build(applicant_id: family.family_members.where(is_primary_applicant: true).first.id, csr_percent_as_integer: 87, is_ia_eligible: true) }
    let!(:tax_household_member2) { tax_household.tax_household_members.build(applicant_id: family.family_members.where(is_primary_applicant: false).first.id, csr_percent_as_integer: 100, is_ia_eligible: true) }

    context "native_american_csr feature enabled and all are indian tribes" do
      before do
        EnrollRegistry[:native_american_csr].feature.stub(:is_enabled).and_return(true)
        tax_household_member1.family_member.person.update_attributes(indian_tribe_member: true)
        tax_household_member2.family_member.person.update_attributes(indian_tribe_member: true)
      end

      it "should return csr_limited" do
        reinstatement = described_class.new(hbx_enrollment, hbx_enrollment.effective_on)
        expect(reinstatement.extract_csr_kind).to eq 'csr_limited'
      end
    end

    context "native_american_csr feature disabled" do
      before do
        EnrollRegistry[:native_american_csr].feature.stub(:is_enabled).and_return(false)
      end

      it "should not return csr_limited" do
        reinstatement = described_class.new(hbx_enrollment, hbx_enrollment.effective_on)
        expect(reinstatement.extract_csr_kind).not_to eq 'csr_limited'
      end

      context "when temporary_configuration_enable_multi_tax_household_feature is disabled" do
        before do
          EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(false)
        end

        it "should return csr_87" do
          reinstatement = described_class.new(hbx_enrollment, hbx_enrollment.effective_on)
          expect(reinstatement.extract_csr_kind).to eq 'csr_87'
        end
      end

      context "when temporary_configuration_enable_multi_tax_household_feature is enabled" do
        before do
          EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
        end

        it 'should return csr_0 for this shopping group' do
          reinstatement = described_class.new(hbx_enrollment, hbx_enrollment.effective_on)
          expect(reinstatement.extract_csr_kind).to eq('csr_0')
        end

        context "with eligibility determination" do
          let(:eligibility_determination) do
            determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
            family.family_members.each do |family_member|
              subject = determination.subjects.create(
                gid: "gid://enroll/FamilyMember/#{family_member.id}",
                is_primary: family_member.is_primary_applicant,
                person_id: family_member.person.id
              )

              state = subject.eligibility_states.create(eligibility_item_key: 'aptc_csr_credit')
              state.grants.create(
                key: "CsrAdjustmentGrant",
                value: csr_value,
                start_on: TimeKeeper.date_of_record.beginning_of_year,
                end_on: TimeKeeper.date_of_record.end_of_year,
                assistance_year: TimeKeeper.date_of_record.year,
                member_ids: family.family_members.map(&:id)
              )
            end

            determination
          end

          let(:csr_value) { '87' }

          it "should return csr_87" do
            eligibility_determination
            reinstatement = described_class.new(hbx_enrollment, hbx_enrollment.effective_on)
            expect(reinstatement.extract_csr_kind).to eq 'csr_87'
          end

          context 'AI/AN members' do
            let!(:product_01) do
              FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                hios_id: "41842ME0400111-01",
                                csr_variant_id: '01',
                                metal_level_kind: :silver)
            end

            let!(:product_02) do
              FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                hios_id: "41842ME0400111-02",
                                csr_variant_id: '02',
                                metal_level_kind: :silver)
            end

            let!(:product_03) do
              FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                hios_id: "41842ME0400111-03",
                                csr_variant_id: '03',
                                metal_level_kind: :silver)
            end

            before do
              hbx_enrollment.product_id = product_01.id
              hbx_enrollment.save!
              family.family_members.map(&:person).each do |per|
                per.update_attributes!(indian_tribe_member: true)
              end
              EnrollRegistry[:native_american_csr].feature.stub(:is_enabled).and_return(true)
            end

            let(:reinstatement_enrollment) { described_class.new(hbx_enrollment, hbx_enrollment.effective_on).build }

            context 'without FA member determination' do
              it 'should return 03 variant product as group is eligible for csr_limited' do
                expect(reinstatement_enrollment.product.csr_variant_id).to eq '03'
                expect(reinstatement_enrollment.product.hios_id.split('-').last).to eq '03'
              end
            end

            context 'FA member determination 94, 87, 73 or 0 csr' do
              let(:csr_value) { ['94', '87', '73', '0'].sample }

              it 'should return 03 variant product as group is eligible for csr_limited' do
                eligibility_determination
                expect(reinstatement_enrollment.product.csr_variant_id).to eq '03'
                expect(reinstatement_enrollment.product.hios_id.split('-').last).to eq '03'
              end
            end

            context 'FA member determination 100 csr' do
              let(:csr_value) { '100' }

              it 'should return 02 variant product as group is eligible for csr_100' do
                eligibility_determination
                expect(reinstatement_enrollment.product.csr_variant_id).to eq '02'
                expect(reinstatement_enrollment.product.hios_id.split('-').last).to eq '02'
              end
            end
          end
        end
      end
    end
  end
end
