require File.join(Rails.root, "app", "data_migrations", "remove_erroneous_personrelationship_records")

# To run rake task: RAILS_ENV=production bundle exec rake migrations:remove_erroneous_personrelationship_records hbx_id="12222222"
namespace :migrations do
  desc "To remove the erroneous person relationship records"
  RemoveErroneousPersonrelationshipRecords.define_task :remove_erroneous_personrelationship_records => :environment
end