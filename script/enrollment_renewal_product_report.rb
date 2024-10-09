# frozen_string_literal: true

# Triggers the EnrollmentRenewalProductReport operation
Operations::Reports::EnrollmentRenewalProductReport.new.call({current_year: current_year.to_i})
