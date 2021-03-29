# frozen_string_literal: true
module Subscribers
  class ApplicantSubscriber
    include EventSource::Subscriber

    subscription 'financial_assistance.applicants_publisher', 'applicants.applicant_created'

    def on_applicants_applicant_created(attributes)
      puts "EA applicant subscription------------->>>>> #{attributes.inspect}"
      # heavy lifting
    end
  end
end
