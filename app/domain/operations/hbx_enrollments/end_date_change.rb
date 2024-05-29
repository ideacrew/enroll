# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  module HbxEnrollments
    #This class updates the termination date of a HBX enrollment.
    # If given termination date is less than enrollment termination -  it updates the enrollment
    # If given termination date is greater than enrollment termination and is a prior year enrollment
    # - it generates a new enrollment.
    class EndDateChange
      include Dry::Monads[:do, :result]

      # @param [ EnrollmentId ] enrollment_id bson_id of a enrollment
      # @param [ NewTerminationDate ] termination_date to update the enrollment
      # @param [ EdiRequired ] edi_required to send the enrollment change to EDI
      # @return [ Success ] :ok
      def call(params:)
        validated_params = yield validate(params)
        @enrollment = yield fetch_enrollment(params["enrollment_id"])
        _status = yield check_enrollment_eligibility(validated_params['new_termination_date'])
        updated_enrollment = yield terminate_enrollment(validated_params)

        end_date_after_effects(updated_enrollment, params["edi_required"].present?)

        Success(:ok)
      end

      private

      def validate(params)
        return Failure("enrollment_id not present") if params["enrollment_id"].blank?
        return Failure("new termination date not present") if params["new_termination_date"].blank?
        Success(params)
      end

      def fetch_enrollment(enrollment_id)
        ::Operations::HbxEnrollments::Find.new.call(id: enrollment_id.to_s)
      end

      def check_enrollment_eligibility(termination_date)
        @termination_date = Date.strptime(termination_date, "%m/%d/%Y")
        eligible_states = %w[coverage_terminated coverage_termination_pending]
        eligible_states << 'coverage_expired' if EnrollRegistry[:change_end_date].settings(:expired_enrollments).item

        return Failure('Enrollment not in valid state') unless eligible_states.include?(@enrollment.aasm_state)

        return Failure('Invalid termination date') if termination_date_check_fails?

        return Failure("Overlapping coverage exists") if check_if_overlapping_coverage_exists?
        Success(:ok)
      end

      def termination_date_check_fails?
        prior_or_current_py_enr = @enrollment.prior_plan_year_coverage? || @enrollment.active_plan_year_coverage?

        if prior_or_current_py_enr
          term_or_expiration_date = @enrollment.is_shop? ? @enrollment&.sponsored_benefit_package&.end_on : @enrollment&.effective_on&.end_of_year
          @termination_date > term_or_expiration_date
        else
          @termination_date > @enrollment.terminated_on
        end
      end

      def terminate_enrollment(params)
        return Success('Enrollment updated') if @enrollment.cancel_terminated_enrollment(@termination_date, params['edi_required'].present?)

        if !@enrollment.coverage_expired? && (@termination_date > @enrollment.terminated_on)
          reinstate_enrollment
        else
          update_end_date
        end
      end

      def reinstate_enrollment
        reinstate_enrollment = Enrollments::Replicator::Reinstatement.new(@enrollment, @enrollment.terminated_on.next_day).build

        can_reinstate = ::Operations::Products::ProductOfferedInServiceArea.new.call({enrollment: reinstate_enrollment})
        return can_reinstate unless can_reinstate.success?

        if reinstate_enrollment.may_reinstate_coverage?
          reinstate_enrollment.reinstate_coverage!
          # Move reinstated enrollment to "coverage selected" status
          reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage?

          #transition enrollment to term state if PY terminated
          reinstate_enrollment.term_or_expire_enrollment(@termination_date)
        end
        Success(reinstate_enrollment)
      end

      def update_end_date
        state = @enrollment.aasm_state
        if @enrollment.is_shop? && (@termination_date > ::TimeKeeper.date_of_record && @enrollment.may_schedule_coverage_termination?)
          @enrollment.schedule_coverage_termination!(@termination_date)
        elsif @enrollment.may_terminate_coverage?
          @enrollment.terminated_on = @termination_date
          @enrollment.terminate_coverage!(@termination_date)
        end
        cancel_renewal_enrollments(@enrollment) if state == 'coverage_expired'
        Success(@enrollment)
      end

      def check_if_overlapping_coverage_exists?
        return false unless @enrollment.prior_plan_year_coverage? || @enrollment.active_plan_year_coverage?

        @enrollment.is_shop? ? check_for_overlapping_shop_enrollments : check_for_overlapping_ivl_enrollments
      end

      def check_for_overlapping_shop_enrollments
        eligible_states = HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::CAN_REINSTATE_AND_UPDATE_END_DATE
        eligible_states << 'coverage_expired' if EnrollRegistry[:change_end_date].settings(:expired_enrollments).item
        HbxEnrollment.where({:family_id => @enrollment.family_id,
                             :kind.in => %w[employer_sponsored employer_sponsored_cobra],
                             :effective_on => { "$gte" => @enrollment.terminated_on, "$lte" => @termination_date },
                             :coverage_kind => @enrollment.coverage_kind,
                             :employee_role_id => @enrollment.employee_role_id,
                             :aasm_state.in => eligible_states}).any?
      end

      def check_for_overlapping_ivl_enrollments
        eligible_states = HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::CAN_REINSTATE_AND_UPDATE_END_DATE
        eligible_states << 'coverage_expired' if EnrollRegistry[:change_end_date].settings(:expired_enrollments).item
        HbxEnrollment.where({:family_id => @enrollment.family_id,
                             :kind.in => %w[individual coverall],
                             :effective_on => { "$gte" => @enrollment.terminated_on, "$lte" => @termination_date },
                             :coverage_kind => @enrollment.coverage_kind,
                             :consumer_role_id => @enrollment.consumer_role_id,
                             :aasm_state.in => eligible_states}).any?
      end

      def end_date_after_effects(updated_enrollment, edi_required)
        updated_enrollment.notify_enrollment_cancel_or_termination_event(edi_required)
      end

      def cancel_renewal_enrollments(updated_enrollment)
        if updated_enrollment.is_shop?
          cancel_shop_enrollments(updated_enrollment)
        else
          cancel_ivl_enrollments(updated_enrollment)
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def cancel_ivl_enrollments(updated_enrollment)
        coverage_period_start = updated_enrollment.effective_on.end_of_year.next_day
        benefit_coverage_period_year = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_period_by_effective_date(coverage_period_start)&.start_on&.year

        return unless benefit_coverage_period_year
        renewal_enrollments = updated_enrollment.family.hbx_enrollments.by_coverage_kind(updated_enrollment.coverage_kind).by_year(benefit_coverage_period_year).show_enrollments_sans_canceled.by_kind(updated_enrollment.kind)
        renewal_enrollments.each do |enr|
          next unless enr&.subscriber&.applicant_id == updated_enrollment&.subscriber&.applicant_id
          next if (enr.hbx_enrollment_members.map(&:applicant_id) - updated_enrollment.hbx_enrollment_members.map(&:applicant_id)).any?
          next if (updated_enrollment.hbx_enrollment_members.map(&:applicant_id) - enr.hbx_enrollment_members.map(&:applicant_id)).any?
          next unless enr.effective_on == updated_enrollment.effective_on.next_year.beginning_of_year
          next unless product_matched(enr, updated_enrollment)
          enr.cancel_ivl_enrollment
          cancel_ivl_enrollments(enr)
        end
      end

      def product_matched(enr, enrollment)
        return false unless enr.product.present?
        return true if enr.product_id == enrollment&.product&.renewal_product&.id
        return true if enr.product.hios_base_id == enrollment&.product&.renewal_product&.hios_base_id
        enr.product.issuer_profile_id == enrollment&.product&.renewal_product&.issuer_profile_id
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def cancel_shop_enrollments(updated_enrollment)
        eligible_state = ::BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES
        successor_application = updated_enrollment.sponsored_benefit_package.benefit_application.successors.select{ |app| eligible_state.include?(app.aasm_state)}.first
        return if successor_application.blank?

        successor_enrollments = renewal_enrollments(successor_application, updated_enrollment).where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + ['renewing_waived', 'inactive'])
        successor_enrollments.each do |enr|
          enr.cancel_shop_enrollment
          cancel_shop_enrollments(enr)
        end
      end

      def renewal_enrollments(successor_application, enrollment)
        HbxEnrollment.where({ :sponsored_benefit_package_id.in => successor_application.benefit_packages.pluck(:_id),
                              :coverage_kind => enrollment.coverage_kind,
                              :kind => enrollment.kind,
                              :family_id => enrollment.family_id,
                              :effective_on => successor_application.start_on})
      end
    end
  end
end
