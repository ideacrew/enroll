module Notifier
  module Builders::BenefitApplication
    include ActionView::Helpers::NumberHelper

    def benefit_application_current_py_start_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_start_date = format_date(current_benefit_application.start_on)
      end
    end

    def benefit_application_current_py_end_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_end_date = format_date(current_benefit_application.end_on)
      end
    end

    def benefit_application_renewal_py_start_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_start_date = format_date(renewal_benefit_application.start_on)
      end
    end

    def benefit_application_next_available_start_date
      schedular =  BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      merge_model.benefit_application.next_available_start_date = schedular.calculate_start_on_dates.first.to_date
    end

    def benefit_application_next_application_deadline
      merge_model.benefit_application.next_application_deadline = Date.new(plan_year_next_available_start_date.year, plan_year_next_available_start_date.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month)
    end

    def benefit_application_renewal_py_end_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_end_date = format_date(renewal_benefit_application.end_on)
      end
    end

    def benefit_application_current_py_oe_start_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_oe_start_date = format_date(current_benefit_application.open_enrollment_period.min)
      end
    end

    def benefit_application_monthly_employer_contribution_amount
      if current_benefit_application.present?
        payment = current_benefit_application.benefit_groups.map(&:monthly_employer_contribution_amount)
        merge_model.benefit_application.monthly_employer_contribution_amount = number_to_currency(payment.inject(0){ |sum,a| sum+a })
      end
    end

    def benefit_application_current_py_plus_60_days
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_plus_60_days = format_date(current_benefit_application.end_on + 60.days)
      end
    end

    def benefit_application_current_py_oe_end_date
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_oe_end_date = format_date(current_benefit_application.open_enrollment_period.max)
      end
    end

    def benefit_application_renewal_py_oe_start_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_oe_start_date = format_date(renewal_benefit_application.open_enrollment_period.min)
      end
    end

    def benefit_application_renewal_py_oe_end_date
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_oe_end_date = format_date(renewal_benefit_application.open_enrollment_period.max)
      end
    end

    def benefit_application_initial_py_publish_advertise_deadline
      if current_benefit_application.present?
        prev_month = current_benefit_application.start_on.prev_month
        merge_model.benefit_application.initial_py_publish_advertise_deadline = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month))
      end
    end

    def benefit_application_initial_py_publish_due_date
      if current_benefit_application.present?
        prev_month = current_benefit_application.start_on.prev_month
        merge_model.benefit_application.initial_py_publish_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month))
      end
    end

    def benefit_application_renewal_py_submit_soft_due_date
      if renewal_benefit_application.present?
        prev_month = renewal_benefit_application.start_on.prev_month
        merge_model.benefit_application.renewal_py_submit_soft_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline))
      end
    end

    def benefit_application_renewal_py_submit_due_date
      if renewal_benefit_application.present?
        prev_month = renewal_benefit_application.start_on.prev_month
        merge_model.benefit_application.renewal_py_submit_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month))
      end
    end

    def benefit_application_binder_payment_due_date
      if current_benefit_application.present?
        schedular =  BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        merge_model.benefit_application.binder_payment_due_date = format_date(schedular.map_binder_payment_due_date_by_start_on(current_benefit_application.start_on))
      end
    end

    def benefit_application_current_py_start_on
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_start_on = current_benefit_application.start_on
      end
    end

    def benefit_application_current_py_end_on
      if current_benefit_application.present?
        merge_model.benefit_application.current_py_end_on = current_benefit_application.end_on
      end
    end

    def benefit_application_renewal_py_start_on
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_start_on = renewal_benefit_application.start_on
      end
    end

    def benefit_application_total_enrolled_count
      if load_benefit_application.present?
        merge_model.benefit_application.total_enrolled_count = load_benefit_application.total_enrolled_count
      end
    end

    def benefit_application_eligible_to_enroll_count
      if load_benefit_application.present?
        merge_model.benefit_application.eligible_to_enroll_count = load_benefit_application.eligible_to_enroll_count
      end
    end

    def benefit_application_renewal_py_end_on
      if renewal_benefit_application.present?
        merge_model.benefit_application.renewal_py_end_on = renewal_benefit_application.end_on
      end
    end

    def benefit_application_enrollment_errors
      enrollment_errors = []
      plan_year = (renewal_benefit_application || current_benefit_application)
      if plan_year.present?
        plan_year.enrollment_errors.each do |k, _|
          case k.to_s
          when "enrollment_ratio"
            enrollment_errors << "At least 75% of your eligible employees enrolled in your group health coverage or waive due to having other coverage"
          when "non_business_owner_enrollment_count"
            enrollment_errors << "One non-owner employee enrolled in health coverage"
          end
        end
        merge_model.benefit_application.enrollment_errors = enrollment_errors.join(' AND/OR ')
      end
    end

    def benefit_application_warnings
      plan_year_warnings = []
      if current_benefit_application.present?
        current_benefit_application.application_eligibility_warnings.each do |k, _|
          case k.to_s
          when "fte_count"
            plan_year_warnings << "Full Time Equivalent must be 1-50"
          when "primary_office_location"
            plan_year_warnings << "primary business address not located in #{Settings.aca.state_name}"
          end
        end
      end
      merge_model.benefit_application.warnings = plan_year_warnings.join(', ')
    end

    def load_benefit_application
      benefit_application = nil
      if payload['event_object_kind'].constantize == BenefitSponsors::BenefitApplications::BenefitApplication
        benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.find(payload['event_object_id'])
      end

      if benefit_application.blank? && enrollment.present?
        if enrollment.sponsored_benefit_package
          benefit_application = enrollment.sponsored_benefit_package.benefit_application
        end
      end

      benefit_application
    end

    def current_benefit_application
      return @current_benefit_application if defined? @current_benefit_application
      benefit_application = load_benefit_application
      if benefit_application.present?
        if benefit_application.is_renewing? || benefit_application.enrollment_ineligible? || benefit_application.canceled?
          @current_benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.detect{|ba| ba.is_published? && ba.start_on == benefit_application.start_on.prev_year}
        else
          @current_benefit_application = benefit_application
        end
      end
    end

    def renewal_benefit_application
      return @renewal_benefit_application if defined? @renewal_benefit_application
      benefit_application = load_benefit_application
      if benefit_application.present?
        if benefit_application.is_renewing? || benefit_application.enrollment_ineligible? || benefit_application.canceled?
          @renewal_benefit_application = benefit_application
        else
          @renewal_benefit_application = employer_profile.active_benefit_sponsorship.benefit_applications.detect{|ba| ba.is_published? && ba.start_on == benefit_application.start_on.prev_year}
        end
      end
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end
