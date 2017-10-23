module Notifier
  module Builders::PlanYear
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

    def plan_year_current_py_oe_end_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_end_date = format_date(current_plan_year.open_enrollment_end_on)
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

    def plan_year_renewal_py_end_on
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_on = renewal_plan_year.end_on
      end
    end
  end
end