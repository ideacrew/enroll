# frozen_string_literal: true

module Subscribers
  # To receive payloads for MCR migration
  class SubmitIapRenewalDraft
    include Acapi::Notifiers
    include Dry::Monads[:result, :do, :try]

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "submit_mcr_iap_renewal_draft",
          :kind => :direct,
          :routing_key => "info.events.mcr.submit_iap_renewal_draft"
      )
    end

    def work_with_params(body, _delivery_info, _properties)
      begin
        payload = JSON.parse(body, :symbolize_names => true)
        result = Operations::Ffe::SubmitIapRenewalTest.new.call(payload)
        if result.success?
          notify("acapi.info.events.mcr.submit_iap_application_success", {:body => JSON.dump({payload: payload, result: result})})
        else
          notify("acapi.info.events.mcr.submit_iap_application_failure", {:body => JSON.dump({payload: payload, result: result})})
        end
      rescue StandardError => e
        notify("acapi.info.events.mcr.submit_iap_application_exception", {:body => JSON.dump({:payload => payload,
                                                                                       :result => result,
                                                                                       :error => e.inspect,
                                                                                       :message => e.message,
                                                                                       :backtrace => e.backtrace
                                                                                      })})
      end
      :ack
    end
  end
end


# include Acapi::Notifiers
# ::FinancialAssistance::Application.by_year(2022).renewal_draft.each do |application|
#   payload = {_id: application.id.to_s}
#   notify("acapi.info.events.mcr.submit_mcr_iap_renewal_draft", {:body => JSON.dump(payload)})
# end

# FinancialAssistance::Application.by_year(2022).renewal_draft.each do |application|
#   if application.have_permission_to_renew?
#     if application.may_submit? && application.is_application_valid?
#       application.submit!
#     else
#       puts "application not valid #{application.id}"
#     end
#   else
#     application.set_income_verification_extension_required!
#     puts "income verification required #{application.id}"
#   end
# end


