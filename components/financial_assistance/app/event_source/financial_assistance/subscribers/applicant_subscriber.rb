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

      subscription 'financial_assistance.applicants_publisher', 'applicants.applicant_created'
      # subscription 'parties.person_publisher', 'parties.person.updated'

      # subscription 'parties.organization_publisher'
      
      # subscription 'financial_assistance.parties.applicant_publisher',
      #   'financial_assistance.parties.applicant.created'

      # subscription 'financial_assistance.parties.applicant_publisher',
      #               async: {
      #                 event: 'financial_assistance.parties.applicant.created',
      #                 job: 'FinancialAssistance::ApplicantJob'
      #               }

      # subscription 'financial_assistance.parties.applicant.created',
      #               {event_key: 'financial_assistance.parties.applicant.created'},
      #               lambda {|payload| FinancialAssistance::ApplicantJob.preform(payload) }
    
      
      # subscription 'financial_assistance.parties.applicant.created', {adapter: EventSource.adapter},
      #         lambda {|payload| FinancialAssistance::ApplicantJob.preform(payload) }

      # # subscription 'financial_assistance.parties.applicant_publisher',
      #               async: {
      #                 event: 'financial_assistance.parties.applicant.updated',
      #                 job: 'FinancialAssistance::ApplicantJob'
      #               }

      def on_applicants_applicant_created(attributes)
        puts "FAA applicant subscription------------->>>>> #{attributes.inspect}"
      end
    end
  end
end


