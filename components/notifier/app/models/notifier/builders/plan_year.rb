module Notifier
  module Builders::PlanYear
    include ActionView::Helpers::NumberHelper

    def plan_year_benefit_groups
      benefit_groups = load_plan_year.benefit_groups
      merge_model.plan_year.benefit_groups = build_benefit_groups(benefit_groups)
    end

    def build_benefit_groups(benefit_groups)
      benefit_groups.collect do |b_group|
        benefit_group = Notifier::MergeDataModels::BenefitGroup.new
        benefit_group.start_on = b_group.start_on
        benefit_group.title = b_group.title.titleize
        benefit_group.plan_option_kind = b_group.plan_option_kind
        benefit_group.reference_plan_name = b_group.reference_plan.name.titleize
        benefit_group.reference_plan_carrier_name = b_group.reference_plan.carrier_profile.legal_name.titleize
        benefit_group.relationship_benefits = build_relationship_benefits(b_group.relationship_benefits.compact)
        benefit_group.plan_offerings_text = plan_offerings_text(b_group)
        benefit_group
      end
    end

    def plan_offerings_text(benefit_group)
      case benefit_group.plan_option_kind
      when "single_carrier"
        "All plans from #{benefit_group.reference_plan.carrier_profile.legal_name}"
      when "metal_level"
        "#{benefit_group.reference_plan.metal_level.titleize} metal level"
      when "single_plan"
        "#{benefit_group.reference_plan.carrier_profile.legal_name.titleize} - #{benefit_group.reference_plan.name.titleize}"
      end
    end

    def build_relationship_benefits(relationship_benefits)
      relationship_benefits.reject{ |rel_ben| rel_ben.relationship == 'child_26_and_over' }.collect do |relationship_benefit|
        rel_benefit = Notifier::MergeDataModels::RelationshipBenefit.new
        rel_benefit.relationship = relationship_benefit.relationship.titleize
        rel_benefit.premium_pct = number_to_percentage(relationship_benefit.premium_pct, precision: 0)
        rel_benefit
      end
    end

    def plan_year_current_py_start_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_start_date = format_date(current_plan_year.start_on)
      end
    end

    def plan_year_current_py_end_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_end_date = format_date(current_plan_year.end_on)
      end
    end

    def plan_year_renewal_py_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_start_date = format_date(renewal_plan_year.start_on)
      end
    end

    def plan_year_renewal_year
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_year = renewal_plan_year.start_on.year.to_s
      end
    end

    def plan_year_current_year
      if current_plan_year.present?
        merge_model.plan_year.current_year = current_plan_year.start_on.year.to_s
      end
    end

    def plan_year_next_available_start_date
      merge_model.plan_year.next_available_start_date = PlanYear.calculate_start_on_options.first.last.to_date
    end

    def plan_year_next_application_deadline
      merge_model.plan_year.next_application_deadline = Date.new(plan_year_next_available_start_date.year, plan_year_next_available_start_date.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month)
    end

    def plan_year_renewal_py_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_date = format_date(renewal_plan_year.end_on)
      end
    end

    def plan_year_current_py_oe_start_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_start_date = format_date(current_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_monthly_employer_contribution_amount
      if current_plan_year.present?
        payment = current_plan_year.benefit_groups.map(&:monthly_employer_contribution_amount)
        merge_model.plan_year.monthly_employer_contribution_amount = number_to_currency(payment.inject(0){ |sum,a| sum+a })
      end
    end

    def plan_year_current_py_plus_60_days
      if current_plan_year.present?
        merge_model.plan_year.current_py_plus_60_days = format_date(current_plan_year.end_on + 60.days)
      end
    end

    def plan_year_py_end_on_plus_60_days
      if current_or_renewal_py.present?
        merge_model.plan_year.py_end_on_plus_60_days = format_date(current_or_renewal_py.end_on + 60.days)
      end
    end

    def plan_year_group_termination_plus_31_days
      if load_plan_year.present?
        merge_model.plan_year.group_termination_plus_31_days = format_date(load_plan_year.end_on + 31.days)
      end
    end

    def plan_year_current_py_oe_end_date
      plan_year =
        if event_name == 'zero_employees_on_roster_notice' || event_name == 'low_enrollment_notice_for_employer'
          load_plan_year
        else
          current_plan_year
        end

      if plan_year.present?
        merge_model.plan_year.current_py_oe_end_date = format_date(plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_renewal_py_oe_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_start_date = format_date(renewal_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_renewal_py_oe_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_end_date = format_date(renewal_plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_initial_py_publish_advertise_deadline
      if current_plan_year.present?
        prev_month = current_plan_year.start_on.prev_month
        merge_model.plan_year.initial_py_publish_advertise_deadline = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month))
      end
    end

    def plan_year_initial_py_publish_due_date
      if current_plan_year.present?
        prev_month = current_plan_year.start_on.prev_month
        merge_model.plan_year.initial_py_publish_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month))
      end
    end

    def plan_year_renewal_py_submit_soft_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_soft_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline))
      end
    end

    def plan_year_renewal_py_submit_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month))
      end
    end

    def plan_year_binder_payment_due_date
      if current_plan_year.present?
        merge_model.plan_year.binder_payment_due_date = format_date(PlanYear.map_binder_payment_due_date_by_start_on(current_plan_year.start_on))
      end
    end

    def plan_year_current_py_start_on
      if current_plan_year.present?
        merge_model.plan_year.current_py_start_on = current_plan_year.start_on
      end
    end

    def plan_year_current_py_end_on
      if current_plan_year.present?
        merge_model.plan_year.current_py_end_on = current_plan_year.end_on
      end
    end

    def plan_year_renewal_py_start_on
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_start_on = renewal_plan_year.start_on
      end
    end

    def plan_year_total_enrolled_count
      if load_plan_year.present?
        merge_model.plan_year.total_enrolled_count = load_plan_year.total_enrolled_count
      end
    end

    def plan_year_eligible_to_enroll_count
      if load_plan_year.present?
        merge_model.plan_year.eligible_to_enroll_count = load_plan_year.eligible_to_enroll_count
      end
    end

    def plan_year_renewal_py_end_on
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_on = renewal_plan_year.end_on
      end
    end

    def plan_year_enrollment_errors
      enrollment_errors = []
      plan_year = (renewal_plan_year || current_plan_year)
      if plan_year.present?
         plan_year.enrollment_errors.each do |k, v|
          case k.to_s
          when "eligible_to_enroll_count"
            enrollment_errors << "at least one employee must be eligible to enroll"
          when "non_business_owner_enrollment_count"
            enrollment_errors << "at least #{Settings.aca.shop_market.non_owner_participation_count_minimum} non-owner employee must enroll"
          when "enrollment_ratio"
            unless plan_year.effective_date.yday == 1
              enrollment_errors << "number of eligible participants enrolling (#{plan_year.total_enrolled_count}) is less than minimum required #{plan_year.minimum_enrolled_count}"
            end
          end
        end
        merge_model.plan_year.enrollment_errors = enrollment_errors.join(' AND/OR ')
      end
    end

    def plan_year_warnings
      plan_year_warnings = []
      plan_year = current_plan_year || renewal_plan_year
      if plan_year.present?
        plan_year.application_eligibility_warnings.each do |k, _|
          case k.to_s
          when "fte_count"
            plan_year_warnings << "Full Time Equivalent must be 1-50"
          when "primary_office_location"
            plan_year_warnings << "primary business address not located in #{Settings.aca.state_name}"
          end
        end
      end
      merge_model.plan_year.warnings = plan_year_warnings.join(', ')
    end

    def load_plan_year
      return @plan_year if defined? @plan_year

      if payload['event_object_kind'].constantize == PlanYear
        @plan_year = employer_profile.plan_years.find(payload['event_object_id'])
      end

      if @plan_year.blank? && enrollment.present?
        if enrollment.benefit_group
          @plan_year = enrollment.benefit_group.plan_year
        end
      end

      if @plan_year.blank? && event_name == 'out_of_pocker_url_notifier'
        @plan_year = employer_profile.plan_years.published_or_renewing_published.first
      end

      @plan_year
    end

    def current_plan_year
      return @current_plan_year if defined? @current_plan_year
      plan_year = load_plan_year
      if plan_year.present?
        if plan_year.is_renewing? || plan_year.renewing_application_ineligible? || plan_year.renewing_canceled?
          @current_plan_year = employer_profile.plan_years.detect{|py| py.is_published? && py.start_on == plan_year.start_on.prev_year}
        else
          @current_plan_year = plan_year
        end
      end
    end

    def renewal_plan_year
      return @renewal_plan_year if defined? @renewal_plan_year
      plan_year = load_plan_year
      if plan_year.present?
        if plan_year.is_renewing? || plan_year.renewing_application_ineligible? || plan_year.renewing_canceled?
          @renewal_plan_year = plan_year
        else
          @renewal_plan_year = employer_profile.plan_years.detect{|py| py.is_published? && py.start_on == plan_year.start_on.prev_year}
        end
      end
    end

    def current_or_renewal_py
      plan_year = current_plan_year || renewal_plan_year
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end
