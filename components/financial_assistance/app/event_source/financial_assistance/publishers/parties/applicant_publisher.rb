# frozen_string_literal: true
require 'dry/events/publisher'
module FinancialAssistance
  module Parties
    class ApplicantPublisher
      # include Dry::Events::Publisher['financial_assistance.parties.applicant_publisher']
      queue :'financial_assistance.parties.applicant_publisher'

      # Subscribers may register for block events directly in publisher class
      register_event 'financial_assistance.parties.applicant.created'
      register_event 'financial_assistance.parties.applicant.updated'
    end
  end
end

# adapter -> adapters

# dispatchers
# dispatch
#    susbcribe

# publishers
#   - publisher_one
#     - active_support adapter
#   - publisher_two
#     - dry event adapter

# subscribers
#   - subscriber_one
#     - publisher_key :publisher_two
#     publisher.adapter.subscribe()
#   - subscriber_two
#     - publisher_key :publisher_one


# events