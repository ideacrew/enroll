module FinancialAssistance
  class ApplicantJob < ActiveJob::Base
    queue_as :default

    def perform(*options)
      puts "-----listener job"

      # ActiveSupport::Notifications.instrument "my.custom.event"
      # Do something later
    end
  end
end
