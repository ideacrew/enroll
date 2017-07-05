module Exchanges
  module EmployerApplicationsHelper

    def can_termiante_application?(plan_year)
      (plan_year.active? || plan_year.expired? || plan_year.suspended?) && plan_year.may_terminate?
    end

    def can_cancel_application?(plan_year)
      return false if plan_year.active? || plan_year.expired? || TimeKeeper.date_of_record >= plan_year.start_on
      return false if plan_year.enrolled? || plan_year.renewing_enrolled? || plan_year.application_ineligible? || plan_year.renewing_application_ineligible?
      true
    end
  end
end