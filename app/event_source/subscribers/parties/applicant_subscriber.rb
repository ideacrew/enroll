# frozen_string_literal: true
module Parties
  class ApplicantSubscriber
    include ::EventSource::Subscriber

    # subscription 'financial_assistance.parties.applicant_publisher'
    # subscription 'parties.organization_publisher'
    #                async: {
    #                 event: [
    #                   'financial_assistance.parties.applicant.created',
    #                   'financial_assistance.parties.applicant.updated'
    #                 ],
    #                 job: 'FinancialAssistance::ApplicantJob'
    #               }

    # def on_financial_assistance_parties_applicant_created(event)
    #   puts "On Applicant Created Event: #{event.inspect}"
    # end

    # def on_financial_assistance_parties_applicant_updated(event)
    #   puts "On Applicant Updated Event: #{event.inspect}"
    # end
  end
end