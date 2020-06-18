# This rake task used to update phone records on person. check ticket #19754
# RAILS_ENV=production bundle exec rake hbxit:trigger_from_endpoint

namespace :hbxinternal do
  desc "testing triggering rake execution from endpoint"
  task :trigger_from_endpoint => :environment do
    puts "running hbxinternal rake task"
  end
end