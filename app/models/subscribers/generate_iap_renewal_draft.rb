# frozen_string_literal: true

module Subscribers
  # To receive payloads for MCR migration
  class GenerateIapRenewalDraft
    include Acapi::Notifiers
    include Dry::Monads[:result, :do, :try]

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
        :queue_name => "generate_mcr_iap_renewal_draft",
        :kind => :direct,
        :routing_key => "info.events.mcr.generate_iap_renewal_draft"
      )
    end

    def work_with_params(body, _delivery_info, _properties)
      begin
        payload = JSON.parse(body, :symbolize_names => true)
        result = Operations::Ffe::CreateApplicationRenewalTest.new.call(payload)
        if result.success?
          notify("acapi.info.events.mcr.iap_application_success", {:body => JSON.dump({payload: payload})})
        else
          notify("acapi.info.events.mcr.iap_application_failure", {:body => JSON.dump({payload: payload})})
        end
      rescue SystemStackError, StandardError => e
        notify("acapi.info.events.mcr.iap_application_exception", {:body => JSON.dump({:payload => payload,
                                                                                       :result => result,
                                                                                       :error => e.inspect,
                                                                                       :message => e.message,
                                                                                       :backtrace => e.backtrace})})
      end
      :ack
    end
  end
end

# include Acapi::Notifiers
# ::FinancialAssistance::Application.by_year(renewal_year.pred).renewal_eligible.distinct(:family_id).each do |fam|
#   payload = {family_id: fam.to_s, renewal_year: 2022}
#   notify("acapi.info.events.mcr.generate_iap_renewal_draft", {:body => JSON.dump(payload)})
# end

