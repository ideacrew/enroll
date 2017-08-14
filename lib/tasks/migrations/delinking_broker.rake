require File.join(Rails.root, "app", "data_migrations", "delinking_broker")
namespace :migrations do
  desc "Delinking broker"
  DelinkingBroker.define_task :delinking_broker => :environment
end 
