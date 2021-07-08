require File.join(Rails.root, "app", "data_migrations", "create_all_qualifying_life_event_kinds")

# RAILS_ENV=production bundle exec rake migrations:create_all_qualifying_life_event_kinds

namespace :migrations do
  desc "load all qle kinds"
  CreateAllQualifyingLifeEventKinds.define_task :create_all_qualifying_life_event_kinds => :environment
end

