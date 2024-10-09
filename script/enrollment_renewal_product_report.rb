# frozen_string_literal: true

# Triggers the EnrollmentRenewalProductReport operation
# current_year=2024 bundle exec rails runner script/product_cross_walk_enrollment_report.rb
Operations::Reports::EnrollmentRenewalProductReport.new.call({current_year: current_year.to_i})
