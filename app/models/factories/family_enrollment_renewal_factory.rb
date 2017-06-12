module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    attr_accessor :family, :census_employee, :employer, :renewing_plan_year, :enrollment, :disable_notifications

    def initialize
      @disable_notifications = false
    end

    def renew
      raise ArgumentError unless defined?(family)
      @plan_year_start_on = renewing_plan_year.start_on
      @active_plan_year = employer.plan_years.published_and_expired_plan_years_by_date(@plan_year_start_on.prev_day).first

      raise FamilyEnrollmentRenewalFactoryError, 'Active plan year missing' if @active_plan_year.blank?

      HbxEnrollment::COVERAGE_KINDS.each do |coverage_kind|
        next unless employer_offering_coverage_kind?(coverage_kind)
        active_enrollment = find_active_coverage(coverage_kind)

        begin
          if active_enrollment.present?

            renewal_enrollments = find_renewal_enrollments(coverage_kind)
            passive_renewals = renewal_enrollments.renewing

            if renewal_enrollments.enrolled_and_waived.present?
              passive_renewals.each{|e| e.cancel_coverage! if e.may_cancel_coverage?}
            else
              if passive_renewals.blank?
                if active_enrollment.present? && active_enrollment.inactive?
                  renew_enrollment(enrollment: active_enrollment, waiver: true, coverage_kind: coverage_kind)
                  trigger_notice { "employee_open_enrollment_unenrolled" }
                elsif renewal_plan_offered_by_er?(active_enrollment)
                  renew_enrollment(enrollment: active_enrollment, coverage_kind: coverage_kind)
                  trigger_notice { "employee_open_enrollment_auto_renewal" }
                else
                  renew_enrollment(enrollment: nil, waiver: true, coverage_kind: coverage_kind)
                  trigger_notice { "employee_open_enrollment_no_auto_renewal" }
                end
              end
            end
          elsif find_renewal_enrollments(coverage_kind).blank?
            renew_enrollment(enrollment: nil, waiver: true, coverage_kind: coverage_kind)
            trigger_notice { "employee_open_enrollment_unenrolled" }
          end
        rescue Exception => e
          puts "Error found for #{census_employee.full_name} while creating renewals -- #{e.inspect}" unless Rails.env.test?
        end
      end

      family
    end

    def find_active_coverage(coverage_kind)
      shop_enrollments = family.active_household.hbx_enrollments.shop_market.by_coverage_kind(coverage_kind)
      shop_enrollments = shop_enrollments.where({
        :benefit_group_id.in => @active_plan_year.benefit_groups.pluck(:_id),
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['inactive', 'coverage_expired'] - ['coverage_termination_pending']
      })

      shop_enrollments.compact.sort_by{|e| e.submitted_at || e.created_at }.last
    end

    def find_renewal_enrollments(coverage_kind)
      renewal_enrollments = family.active_household.hbx_enrollments.shop_market.by_coverage_kind(coverage_kind)
      renewal_enrollments.where({
        :benefit_group_id.in => renewing_plan_year.benefit_groups.pluck(:_id),
        :effective_on => renewing_plan_year.start_on
        })
    end

    def employer_offering_coverage_kind?(coverage_kind)
      coverage_kind == 'dental' ?
        (census_employee.renewal_benefit_group_assignment.benefit_group.is_offering_dental?) : true
    end

    def renew_enrollment(enrollment: nil, waiver: false, coverage_kind:)
      ShopEnrollmentRenewalFactory.new({
        family: family,
        census_employee: census_employee,
        employer: employer,
        renewing_plan_year: renewing_plan_year,
        enrollment: enrollment,
        is_waiver: waiver,
        coverage_kind: coverage_kind
      }).renew_coverage
    end

    def trigger_notice
      if !disable_notifications
        ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, yield) unless Rails.env.test?
      end
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.present? || enrollment.plan.renewal_plan.present?
        benefit_group = census_employee.renewal_benefit_group_assignment.try(:benefit_group) || renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
        elected_plan_ids = (enrollment.coverage_kind == 'health' ? benefit_group.elected_plan_ids : benefit_group.elected_dental_plan_ids)
        elected_plan_ids.include?(enrollment.plan.renewal_plan_id)
      else
        false
      end
    end
  end

  class FamilyEnrollmentRenewalFactoryError < StandardError; end
end
