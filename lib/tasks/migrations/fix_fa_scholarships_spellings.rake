require File.join(Rails.root, "app", "data_migrations", "fix_fa_scholarships_spellings")
# RAILS_ENV=production bundle exec rake migrations:fix_fa_scholarships_spellings

namespace :migrations do
  desc "Fixes a specific use case where we misspelled scholarship_payments"
  FixFaScholarshipsSpellings.define_task :fix_fa_scholarships_spellings => :environment
end
