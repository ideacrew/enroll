# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::HbxEnrollments::Reinstate, :type => :model, dbclean: :around_each do
  describe 'reinstate enrollment',  dbclean: :around_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 6.months }
    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record - 3.months }
    let(:employee_created_at) { hired_on }
    let(:employee_updated_at) { employee_created_at }
    let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
    let!(:benefit_package) {benefit_sponsorship.benefit_applications.first.benefit_packages.first}
    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
    let(:aasm_state) { :active }
    let(:census_employee) do
      create(:census_employee,
             :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
             benefit_group: current_benefit_package,
             hired_on: hired_on,
             created_at: employee_created_at,
             updated_at: employee_updated_at)
    end
    let!(:family) do
      person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
      census_employee.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    end
    let!(:employee_role){census_employee.employee_role}
    let(:enrollment_kind) { 'open_enrollment' }
    let(:special_enrollment_period_id) { nil }
    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        family: family,
                        effective_on: effective_on,
                        enrollment_kind: enrollment_kind,
                        kind: 'employer_sponsored',
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id,
                        terminate_reason: 'non_payment',
                        product: sponsored_benefit.reference_product,
                        rating_area_id: BSON::ObjectId.new,
                        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
    end

    context 'when enrollment reinstated', dbclean: :around_each do
      let!(:new_bga) do
        enrollment.terminate_coverage!
        current_bga = enrollment.census_employee.benefit_group_assignments.first
        bga_params = current_bga.serializable_hash.deep_symbolize_keys.except(:_id, :workflow_state_transitions)
        bga_params.merge!({start_on: enrollment.terminated_on.next_month.beginning_of_month})
        census_employee.active_benefit_group_assignment.update_attributes(end_on: enrollment.terminated_on)
        census_employee.benefit_group_assignments << ::BenefitGroupAssignment.new(bga_params)
        census_employee.save!
        enrollment.census_employee.reload
        census_employee.benefit_group_assignments.where(start_on: enrollment.terminated_on.next_day).first
      end

      context 'for a terminated enrollment' do
        before do
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end

        it 'should build reinstated enrollment' do
          expect(@reinstated_enrollment.kind).to eq enrollment.kind
          expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should return enrollment in coverage_selected state' do
          expect(@reinstated_enrollment.aasm_state).to eq 'coverage_selected'
        end

        it 'should assign benefit group assignment' do
          expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
        end

        it 'should set parent enrollment' do
          expect(@reinstated_enrollment.parent_enrollment).to eq enrollment
        end

        it 'reinstated enrollment should have new hbx id' do
          expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
        end

        it 'should have continuous coverage' do
          expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment' do
          enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
          expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end
      end

      context "should trigger enrollment event" do
        it 'publish amqp message' do
          expect_any_instance_of(HbxEnrollment).to receive(:notify)
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end
      end

      context 'terminated enrollment, employee future terminated ' do
        before do
          census_employee.terminate_employment(benefit_package.end_on)
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end

        it 'should build reinstated enrollment' do
          expect(@reinstated_enrollment.kind).to eq enrollment.kind
          expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should return enrollment in coverage_termination_pending state' do
          expect(@reinstated_enrollment.aasm_state).to eq 'coverage_termination_pending'
        end

        it 'should set terminated date on enrollment' do
          expect(@reinstated_enrollment.terminated_on).to eq benefit_package.end_on
        end

        it 'should assign benefit group assignment' do
          expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
        end

        it 'reinstated enrollment should have new hbx id' do
          expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
        end

        it 'should have continuous coverage' do
          expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment' do
          enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
          expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end
      end

      context 'for a waived enrollment' do
        before do
          enrollment.update_attributes!(aasm_state: 'shopping', terminate_reason: 'retroactive_canceled')
          enrollment.waive_coverage!
          enrollment.cancel_coverage!
          @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end

        it 'should transition to inactive' do
          expect(@result.aasm_state).to eq('inactive')
        end
      end
    end

    context 'reinstating terminated enrollment, employee terminated in past', dbclean: :after_each do

      let!(:new_bga) do
        census_employee.terminate_employment(TimeKeeper.date_of_record.last_month.end_of_month)
        enrollment.reload
        current_bga = enrollment.census_employee.benefit_group_assignments.first
        bga_params = current_bga.serializable_hash.deep_symbolize_keys.except(:_id, :workflow_state_transitions)
        enrollment.update_attributes(terminated_on: benefit_package.start_on.next_month.end_of_month)
        bga_params.merge!({start_on: enrollment.terminated_on.next_day})
        census_employee.active_benefit_group_assignment.update_attributes(end_on: enrollment.terminated_on)
        census_employee.benefit_group_assignments << ::BenefitGroupAssignment.new(bga_params)
        enrollment.census_employee.reload
        census_employee.benefit_group_assignments.where(start_on: enrollment.terminated_on.next_day).first
      end

      before do
        @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
      end

      it 'should build reinstated enrollment' do
        expect(@reinstated_enrollment.kind).to eq enrollment.kind
        expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should return enrollment in coverage_termination_pending state' do
        expect(@reinstated_enrollment.aasm_state).to eq 'coverage_terminated'
      end

      it 'should set terminated date on enrollment' do
        expect(@reinstated_enrollment.terminated_on).to eq census_employee.employment_terminated_on.end_of_month
      end

      it 'should assign benefit group assignment' do
        expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
      end

      it 'reinstated enrollment should have new hbx id' do
        expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
      end

      it 'should have continuous coverage' do
        expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
      end

      it 'should give same member coverage begin date as base enrollment' do
        enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
        expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end
    end

    context 'when benefit group assignment not found', dbclean: :after_each do
      before do
        enrollment.terminate_coverage!
        new_enr = enrollment.dup
        new_enr.assign_attributes({effective_on: enrollment.terminated_on.next_day})
        new_enr.save!
        enrollment.census_employee.benefit_group_assignments.by_benefit_package(enrollment.sponsored_benefit_package).update_all(end_on: enrollment.terminated_on)
        enrollment.reload
        census_employee.reload
        @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: benefit_package}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq("Active Benefit Group Assignment does not exist for the effective_on: #{enrollment.terminated_on.next_day}")
      end
    end

    context 'overlapping enrollment exists' do
      let!(:new_bga) do
        enrollment.terminate_coverage!
        enrollment.reload
        current_bga = enrollment.census_employee.benefit_group_assignments.first
        bga_params = current_bga.serializable_hash.deep_symbolize_keys.except(:_id, :workflow_state_transitions)
        bga_params.merge!({start_on: enrollment.terminated_on.next_day})
        enrollment.census_employee.benefit_group_assignments << ::BenefitGroupAssignment.new(bga_params)
        enrollment.census_employee.save!
      end

      before do
        new_enr = enrollment.dup
        new_enr.assign_attributes({effective_on: enrollment.terminated_on.next_day})
        new_enr.save!
        @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: benefit_package}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Overlapping coverage exists for this family in current year.')
      end
    end

    context 'when benefit package optional params missing' do
      before do
        enrollment.terminate_coverage!
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing benefit package.')
      end
    end

    context 'when benefit package optional params missing' do
      before do
        enrollment.terminate_coverage!
        allow(enrollment).to receive(:is_shop?).and_return(false)
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a SHOP enrollment.')
      end
    end

    context "reinstate canceled enrollment based on workflow state transitions" do
      before do
        application = benefit_package.benefit_application
        application.cancel!
        enrollment.reload
        enrollment.update_attributes(terminate_reason: '')
        reinstated_app = BenefitSponsors::Operations::BenefitApplications::Reinstate.new.call({params: {benefit_application: application}}).success
        reinstated_package = reinstated_app.benefit_packages.first
        census_employee.reload
        @reinstated_enrollment = HbxEnrollment.where(sponsored_benefit_package_id: reinstated_package.id, effective_on: reinstated_app.start_on).first
        @new_bga = census_employee.benefit_group_assignments.by_benefit_package(reinstated_package).detect{ |bga| bga.is_active?(reinstated_package.start_on)}
      end

      it 'should build reinstated enrollment' do
        expect(@reinstated_enrollment.kind).to eq enrollment.kind
        expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should return enrollment in coverage_selected state' do
        expect(@reinstated_enrollment.aasm_state).to eq 'coverage_enrolled'
      end

      it 'should assign benefit group assignment' do
        expect(@reinstated_enrollment.benefit_group_assignment).to eq @new_bga
      end

      it 'reinstated enrollment should have new hbx id' do
        expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
      end

      it 'should have continuous coverage' do
        expect(@reinstated_enrollment.effective_on).to eq enrollment.effective_on
      end

      it 'should give same member coverage begin date as base enrollment' do
        enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
        expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end
    end
  end
end
