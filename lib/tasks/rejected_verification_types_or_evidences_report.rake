# frozen_string_literal: true

# Rake task to find verification types and evidences in rejected status.
# Run Rake Task: RAILS_ENV=production bundle exec rake reports:rejected_verification_types_or_evidences_report

require File.join(Rails.root, 'app', 'reports', 'rejected_verification_types_or_evidences_report')

namespace :reports do
  desc 'List of people with any verification_type or evidence in rejected status'
  RejectedVerificationTypesOrEvidencesReport.define_task :rejected_verification_types_or_evidences_report => :environment
end
