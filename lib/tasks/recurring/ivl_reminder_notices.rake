# RAILS_ENV=production bundle exec rake recurring:ivl_reminder_notices
namespace :recurring do
  desc "an automation task that sends out verification reminder notifications to IVL individuals"
  task ivl_reminder_notices: :environment do
  end
end