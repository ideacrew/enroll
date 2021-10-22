# frozen_string_literal: true

module Publishers
  # Publishes message to polypress to start pre audit report
  class PreauditReportGenerationPublisher
    include ::EventSource::Publisher[amqp: 'enroll.reports.recon_preaudit']

    register_event 'preaudit_generation_report'
  end
end