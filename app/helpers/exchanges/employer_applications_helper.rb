module Exchanges
  module EmployerApplicationsHelper

    def can_terminate_application?(plan_year)
      (plan_year.active? || plan_year.expired? || plan_year.suspended?) && plan_year.may_terminate?
    end

    def can_cancel_application?(plan_year)
      if (PlanYear::PUBLISHED + PlanYear::RENEWING + ["renewing_application_inelgible"]).include?(plan_year.aasm_state)
        true
      else
        false
      end
    end
  end
end