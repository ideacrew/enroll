# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_bulk_broker_emails")

# Updates broker emails in broke
# RAILS_ENV=production bundle exec rake migrations:update_bulk_broker_emails
namespace :migrations do
  desc "Generates consumers, families, and enrollments for them from existing carriers and plans. Can be run on any environment without affecting existing data. Uses existing carriers/plans."
  UpdateBulkBrokerEmails.define_task :update_bulk_broker_emails => :environment
end