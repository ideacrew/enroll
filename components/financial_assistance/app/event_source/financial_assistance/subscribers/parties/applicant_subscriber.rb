# frozen_string_literal: true
module FinacialAssistance
  module Parties
    class ApplicantSubscriber
      include ::EventSource::Subscriber

      # dispatcher
      #   two adatpers 
      #    rails adapter
      #    dry events adapter
      # one adapter per application

      # subscription 'financial_assistance.parties.applicant_publisher'
      # subscription 'parties.organization_publisher'
      subscription 'financial_assistance.parties.applicant_publisher',
                    async: {
                      event: 'financial_assistance.parties.applicant.created',
                      job: 'FinancialAssistance::ApplicantJob'
                    }

      subscription 'financial_assistance.parties.applicant.created',
                    {event_key: 'financial_assistance.parties.applicant.created'},
                    lambda {|payload| FinancialAssistance::ApplicantJob.preform(payload) }
    
      
      subscription 'financial_assistance.parties.applicant.created', {adapter: EventSource.adapter},
              lambda {|payload| FinancialAssistance::ApplicantJob.preform(payload) }

      # subscription 'financial_assistance.parties.applicant_publisher',
      #               async: {
      #                 event: 'financial_assistance.parties.applicant.updated',
      #                 job: 'FinancialAssistance::ApplicantJob'
      #               }

      def on_financial_assistance_parties_applicant_created(event)
        puts "On Applicant Created Event: #{event.inspect}"
      end

      def on_financial_assistance_parties_applicant_updated(event)
        puts "On Applicant Updated Event: #{event.inspect}"
      end
    end
  end
end


