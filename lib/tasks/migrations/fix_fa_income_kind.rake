require File.join(Rails.root, 'app', 'data_migrations', 'fix_fa_income_kind')
# RAILS_ENV=production bundle exec rake migrations:fix_fa_income_kind

namespace :migrations do
  desc 'Fixes invalid FA Incomes with kind unemployment_insurance'
  FixFaIncomeKind.define_task :fix_fa_income_kind => :environment
end
