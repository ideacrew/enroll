require "forwardable"

module Eligible
  class EligiblePeriodHandler
    extend Forwardable
    def_delegators :@eligible_record, :state_histories, :active_state, :inactive_state, :current_state

    def initialize(eligible_record)
      @eligible_record = eligible_record
    end

    def eligible?
      current_state == active_state
    end

    def is_eligible_on?(date)
      return eligible? if date == TimeKeeper.date_of_record

      eligible_periods.any? do |period|
        if period[:end_on].present?
          (period[:start_on]..period[:end_on]).cover?(date)
        else
          (period[:start_on]..period[:start_on].end_of_year).cover?(date)
        end
      end
    end

    # coverage period of the eligibility will start from the first day of the calendar year
    # in which the eligibility was approved
    # coverage period end on the last day of the calendar year in which the eligibility was denied
    def eligible_periods
      eligible_periods = []
      date_range = {}
      state_histories.non_initial.each do |state_history|
        date_range[
          :start_on
        ] ||= state_history.effective_on if state_history.to_state ==
          active_state

        unless date_range.present? && state_history.to_state == inactive_state
          next
        end
        date_range[:end_on] = state_history.effective_on.prev_day
        eligible_periods << date_range
        date_range = {}
      end

      eligible_periods << date_range unless date_range.empty?
      eligible_periods
    end
  end
end
