require File.join(Rails.root, "app", "data_migrations", "notify_renewal_employees_dental_carriers_exiting_shop")

# Notice to 1/1/2018 Renewal EEs Dental Carriers are Exiting SHOP in 2018
# RAILS_ENV=production bundle exec rake migrations:notify_renewal_employees_dental_carriers_exiting_shop

namespace :migrations do
  desc "Notify Renewal Employees of dental plan carriers are exiting SHOP market"
  NotifyRenewalEmployeesDentalCarriersExitingShop.define_task :notify_renewal_employees_dental_carriers_exiting_shop => :environment
end
