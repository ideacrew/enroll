module Exchanges
  module EmployerApplicationsHelper

    def can_terminate_application?(plan_year)
      (plan_year.active? || plan_year.expired? || plan_year.suspended?) && plan_year.may_terminate?
    end

    def can_cancel_application?(plan_year)
      if plan_year.enrolling? && TimeKeeper.date_of_record < plan_year.start_on
        true
      else
        false
      end
    end
  end
end