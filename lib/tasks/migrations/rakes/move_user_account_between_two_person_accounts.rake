# RAILS_ENV=production bundle exec rake migrations:move_user_account_between_two_person_accounts
# Rake task to move a user account from one person account to another
# Interactive rake that takes input from the user to be completed

require File.join(Rails.root, "app", "data_migrations","rake", "move_user_account_between_two_person_accounts")

namespace :migrations do
  desc "Move User Account between two Person Accounts"
  MoveUserAccountBetweenTwoPersonAccounts.define_task :move_user_account_between_two_person_accounts => :environment
end
