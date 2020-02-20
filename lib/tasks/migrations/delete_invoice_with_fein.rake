require File.join(Rails.root, "app", "data_migrations", "delete_invoice_with_fein")

# RAILS_ENV=production bundle exec rake migrations:delete_invoice_with_fein feins="12345,12345"


namespace :migrations do
  desc "delete current month invoice for given fein"
  DeleteInvoiceWithFein.define_task :delete_invoice_with_fein => :environment
end
