# frozen_string_literal: true

module Operations
  # This class is invoked when a product selection is made.
  # It will execute the side effects of making a product selection, as
  # specific to the DCHBX customer.
  class GeneratePriorPlanYearShopRenewals
    include Dry::Monads[:do, :result]

    # Invoke the operation.
    # @param opts [@enrollment] the invocation options
    def self.call(opts)
      self.new.call(opts)
    end

    # Invoke the operation.
    # @param opts [@enrollment] the invocation options
    def call(opts)
      enrollment = opts[:enrollment]
      return nil unless enrollment.is_shop?
      term_or_expired_enrollment = yield transition_current_enrollment(enrollment)
      result = update_prior_plan_coverage(term_or_expired_enrollment)

      return result if result
      Success(:ok)
    end

    private

    def transition_current_enrollment(enrollment)
      enrollment_benefit_application = enrollment.sponsored_benefit_package.benefit_application
      if enrollment_benefit_application.terminated?
        enrollment.term_or_cancel_enrollment(enrollment, enrollment_benefit_application.end_on, enrollment_benefit_application.termination_reason)
      elsif enrollment_benefit_application.expired?
        enrollment.expire_coverage!
      end
      Success(enrollment)
    end

    def update_prior_plan_coverage(enrollment)
      sep = enrollment.family.latest_active_sep_for(enrollment)
      return nil if sep.blank?
      return nil unless sep.coverage_renewal_flag
      @benefit_applications = renewal_applications(enrollment)
      return if @benefit_applications.empty?
      renew_coverage(enrollment)
    end

    def renewal_applications(enrollment)
      sponsorship = enrollment.benefit_sponsorship
      all_applications = sponsorship.benefit_applications
      start_on = enrollment.sponsored_benefit_package.benefit_application.end_on.next_day
      potential_renewal_applications = sponsorship.benefit_applications.where(:predecessor_id.exists => true,
                                                                              :"effective_period.min" => start_on,
                                                                              :aasm_state.in => [:active, :termination_pending, :terminated])

      reinstated_app = all_applications.where(:reinstated_id.in => potential_renewal_applications.map(&:id))
      if reinstated_app.present?
        potential_renewal_applications + reinstated_app
      else
        potential_renewal_applications
      end
    end

    def census_employee_eligible?(benefit_application, census_employee)
      return false if census_employee.employment_terminated_on.present? && census_employee.employment_terminated_on <= benefit_application.start_on
      benefit_package_ids = benefit_application.benefit_packages.map(&:id)
      @assignment = census_employee.benefit_group_assignments.detect { |benefit_group_assignment| benefit_package_ids.include?(benefit_group_assignment.benefit_package.id) && benefit_group_assignment.is_active?(benefit_application.end_on) }
      return false unless @assignment
      true
    end

    def renew_coverage(enrollment)
      @enrollment = enrollment
      census_employee = @enrollment.employee_role.census_employee
      @benefit_applications.each do |ba|
        next unless census_employee_eligible?(ba, census_employee)
        cancel_renewal_enrollments(ba, @enrollment)
        renewal_enrollment = renew_benefit(@enrollment, @assignment.benefit_package)
        next if renewal_enrollment.blank?
        result = transition_enrollment(renewal_enrollment, ba)
        @enrollment = result.success
        notifier = BenefitSponsors::Services::NoticeService.new
        notifier.deliver(recipient: @enrollment.employee_role, event_object: @enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
      rescue StandardError => e
        Rails.logger.error { "Error renewing coverage for employee #{enrollment.census_employee.full_name}'s due to #{e.backtrace}" }
      end
      @enrollment
    end

    def renew_benefit(enrollment, benefit_package)
      if benefit_package.benefit_application.reinstated_id.present?
        benefit_package.enrollment_reinstate(enrollment)
      else
        enrollment.renew_benefit(benefit_package)
      end
    end

    def cancel_renewal_enrollments(benefit_application, enrollment)
      hbx_enrollments = enrollment.enrollments_for(benefit_application)
      hbx_enrollments.each{|en| en.cancel_coverage! if en.may_cancel_coverage? }
    end

    def transition_enrollment(enrollment, benefit_application)
      enrollment.begin_coverage! if TimeKeeper.date_of_record >= benefit_application.start_on && enrollment.may_begin_coverage?
      enrollment.terminate_coverage_with(benefit_application.end_on) if benefit_application.termination_pending? || benefit_application.terminated?
      Success(enrollment)
    end
  end
end