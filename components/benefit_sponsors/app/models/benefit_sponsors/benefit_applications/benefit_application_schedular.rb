module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationSchedular

      # TODOs
      ## handle late rate scenarios where partial or no benefit product plan/rate data exists for effective date
      ## handle midyear initial enrollments for annual fixed enrollment periods
      def effective_period_by_date(given_date = TimeKeeper.date_of_record, use_grace_period = false)
        given_day_of_month    = given_date.day
        next_month_start      = given_date.end_of_month + 1.day
        following_month_start = next_month_start + 1.month

        if given_day_of_month > open_enrollment_minimum_begin_day_of_month(use_grace_period)
          following_month_start..(following_month_start + 1.year - 1.day)
        else
          next_month_start..(next_month_start + 1.year - 1.day)
        end
      end

      def calculate_start_on_dates(admin_datatable_action = false)
        current_date = TimeKeeper.date_of_record
        start_on = if !admin_datatable_action && (current_date.day > open_enrollment_minimum_begin_day_of_month(true))
          current_date.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        else
          current_date.prev_month.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        end

        end_on = (current_date - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days).beginning_of_month
        dates = (start_on..end_on).select {|t| t == t.beginning_of_month}
      end

      def is_start_on_valid?(start_on)
        check_start_on(start_on)[:result] == "ok"
      end

      # Responsible for calculating all the possible dataes
      def start_on_options_with_schedule(is_renewing, admin_datatable_action = false)
        possible_dates = Hash.new
        calculate_start_on_dates(admin_datatable_action).each do |date|
          next if !admin_datatable_action && !is_start_on_valid?(date)
          possible_dates[date] = enrollment_schedule(date).merge(open_enrollment_dates(is_renewing, date, admin_datatable_action))
        end
        possible_dates
      end

      def open_enrollment_dates(is_renewing, start_on, admin_datatable_action = false)
        calculate_open_enrollment_date(is_renewing, start_on, admin_datatable_action)
      end

      def enrollment_schedule(start_on)
        shop_enrollment_timetable(start_on)
      end

      def enrollment_timetable_by_effective_date(is_renewing, effective_date)
        effective_date            = effective_date.to_date.beginning_of_month
        effective_period          = effective_date..(effective_date + 1.year - 1.day)
        open_enrollment_period    = open_enrollment_period_by_effective_date(is_renewing, effective_date)

        prior_month               = effective_date - 1.month
        binder_payment_due_on     = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)

        open_enrollment_minimum_day     = open_enrollment_minimum_begin_day_of_month
        open_enrollment_period_minimum  = Date.new(prior_month.year, prior_month.month, open_enrollment_minimum_day)..open_enrollment_period.end

        # employer_initial_application_earliest_start_on  = (effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months)
        # employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
        # employer_initial_application_latest_submit_on   = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopPlanYearPublishedDueDayOfMonth}").to_date

        {
          effective_date: effective_date,
          effective_period: effective_period,
          # employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
          # employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
          # employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
          open_enrollment_period: open_enrollment_period,
          open_enrollment_period_minimum: open_enrollment_period_minimum,
          binder_payment_due_on: binder_payment_due_on,
        }
      end

      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
        end

        open_enrollment_end_on_day = Settings.aca.shop_market.open_enrollment.monthly_end_on
        minimum_day = open_enrollment_end_on_day - minimum_length
        if minimum_day > 0
          minimum_day
        else
          1
        end
      end

      def calculate_open_enrollment_date(is_renewing, start_on, admin_datatable_action = nil)
        start_on = start_on.to_date

        # open_enrollment_start_on = [start_on - 1.month, TimeKeeper.date_of_record].max
        # candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year.to_i, open_enrollment_start_on.month.to_i, Settings.aca.shop_market.open_enrollment.monthly_end_on)

        # open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
        #   candidate_open_enrollment_end_on.next_month
        # else
        #   candidate_open_enrollment_end_on
        # end

        open_enrollment_period = open_enrollment_period_by_effective_date(is_renewing, start_on, admin_datatable_action)


        #candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year, open_enrollment_start_on.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)

        #open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
        #  candidate_open_enrollment_end_on.next_month
        #else
        #  candidate_open_enrollment_end_on
        #end

        binder_payment_due_date = map_binder_payment_due_date_by_start_on(is_renewing, start_on)

        {
          open_enrollment_start_on: open_enrollment_period.begin,
          open_enrollment_end_on: open_enrollment_period.end,
          binder_payment_due_date: binder_payment_due_date
        }
      end

      def open_enrollment_period_by_effective_date(is_renewing, start_on, admin_datatable_action = nil)
        open_enrollment_start_on = (start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        if start_on.future?
          open_enrollment_start_on = [open_enrollment_start_on, TimeKeeper.date_of_record].max
        end

        oe_min_days = Settings.aca.shop_market.open_enrollment.minimum_length.days

        oe_monthly_end_on = is_renewing ? Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on : Settings.aca.shop_market.open_enrollment.monthly_end_on

        open_enrollment_end_on   = ("#{start_on.prev_month.year}-#{start_on.prev_month.month}-#{oe_monthly_end_on}").to_date

        if admin_datatable_action && ((open_enrollment_end_on - open_enrollment_start_on) < oe_min_days)
          open_enrollment_end_on = (open_enrollment_start_on + oe_min_days)
        end
        open_enrollment_start_on..open_enrollment_end_on
      end

      def renewal_open_enrollment_dates(start_on)
        open_enrollment_start_on = start_on - 2.months
        open_enrollment_end_on =  Date.new((start_on - 1.month).year, (start_on - 1.month).month, Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on)
        [open_enrollment_start_on, open_enrollment_end_on]
      end

      #TODO: Implement the binder payment due dates using BankHolidaysHelper
      #TODO: Logic around binder payment due dates is not clear at this point. Hence hard-coding the due dates for now.
      def map_binder_payment_due_date_by_start_on(is_renewing, start_on)
        dates_map = {}

        Settings.aca.shop_market.binder_payment_dates.each do |dates_pair|
          dates_map[dates_pair.first[0].to_s] = Date.strptime(dates_pair.first[1], '%Y,%m,%d')
        end

        dates_map[start_on.strftime('%Y-%m-%d')] || enrollment_timetable_by_effective_date(is_renewing, start_on)[:binder_payment_due_on]
      end

      def shop_enrollment_timetable(new_effective_date)
        effective_date = new_effective_date.to_date.beginning_of_month
        prior_month = effective_date - 1.month
        plan_year_start_on = effective_date
        plan_year_end_on = effective_date + 1.year - 1.day
        employer_initial_application_earliest_start_on = (effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days)
        employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
        employer_initial_application_latest_submit_on   = "#{prior_month.year}-#{prior_month.month}-#{Settings.aca.shop_market.initial_application.publish_due_day_of_month}".to_date
        open_enrollment_earliest_start_on     = effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        open_enrollment_latest_start_on       = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth}").to_date
        open_enrollment_latest_end_on         = ("#{prior_month.year}-#{prior_month.month}-#{Settings.aca.shop_market.open_enrollment.monthly_end_on}").to_date
        binder_payment_due_date               = first_banking_date_after ("#{prior_month.year}-#{prior_month.month}-#{Settings.aca.shop_market.binder_payment_due_on}")


        timetable = {
          effective_date: effective_date,
          benefit_application_start_on: plan_year_start_on,
          benefit_application_end_on: plan_year_end_on,
          employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
          employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
          employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
          open_enrollment_earliest_start_on: open_enrollment_earliest_start_on,
          open_enrollment_latest_start_on: open_enrollment_latest_start_on,
          open_enrollment_latest_end_on: open_enrollment_latest_end_on,
          binder_payment_due_date: binder_payment_due_date
        }

        timetable
      end

      def check_start_on(start_on)
        return {result: "ok", msg: ""} if start_on.nil?
        start_on = start_on.to_date
        shop_enrollment_dates = shop_enrollment_timetable(start_on)

        if start_on.day != 1
          result = "failure"
          msg = "start on must be first day of the month"
        elsif TimeKeeper.date_of_record > shop_enrollment_dates[:open_enrollment_latest_start_on]
          result = "failure"
          msg = "must choose a start on date #{(TimeKeeper.date_of_record - HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth + Settings.aca.shop_market.open_enrollment.maximum_length.months.months).beginning_of_month} or later"
        end
        
        {result: (result || "ok"), msg: (msg || "")}
      end

      ## TODO - add holidays
      def first_banking_date_prior(date_value)
        date = date_value.to_date
        date = date - 1 if date.saturday?
        date = date - 2 if date.sunday?
        date
      end

      def first_banking_date_after(date_value)
        date = date_value.to_date
        date = date + 2 if date.saturday?
        date = date + 1 if date.sunday?
        date
      end

      def default_dates_for_coverage_starting_on(is_renewing, coverage_start_date)
        effective_date            = coverage_start_date.to_date.beginning_of_month
        effective_period          = effective_date..(effective_date + 1.year - 1.day)
        open_enrollment_period    = open_enrollment_period_by_effective_date(is_renewing, effective_date)
        {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period,
        }
      end
    end
  end
end
