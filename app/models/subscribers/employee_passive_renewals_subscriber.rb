module Subscribers
  class EmployeePassiveRenewalsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.plan_year.employee_passive_renewals_requested"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private

    def process_response(payload)
      begin
        stringified_payload = payload.stringify_keys
        plan_year_id = stringified_payload["plan_year_id"]
        plan_year = PlanYear.find(plan_year_id)

        open_enrollment_factory = Factories::EmployerOpenEnrollmentFactory.new
        open_enrollment_factory.employer_profile = plan_year.employer_profile
        open_enrollment_factory.date = TimeKeeper.date_of_record
        open_enrollment_factory.renewing_plan_year = plan_year
        open_enrollment_factory.process_family_enrollment_renewals
     
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.employee_passive_renewals_subscriber", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end