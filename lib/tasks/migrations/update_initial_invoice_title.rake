require File.join(Rails.root, "app", "data_migrations", "update_initial_invoice_title")
# This rake task is to update initial invoice title
# RAILS_ENV=production bundle exec rake migrations:update_initial_invoice_title
namespace :migrations do
  desc "update initial invoice title"
  UpdateInitialInvoiceTitle.define_task :update_initial_invoice_title => :environment
end