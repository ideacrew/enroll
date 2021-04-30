class ApplicantCreatedJob < ActiveJob::Base
  queue_as :default

  def perform(*options)
    puts "-----inside applicant created job #{options.inspect}"

    # ActiveSupport::Notifications.instrument "my.custom.event"
    # Do something later
  end
end
