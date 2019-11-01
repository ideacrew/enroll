# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_fehb_oe_dates_and_contribution_cap")
# RAILS_ENV=production bundle exec rake migrations:UpdateFehbOeDatesAndContributionCap feins='042266782 042919603 593832832' effective_on=01/01/2020 oe_start_on=11/11/2019 oe_end_on=12/09/2019 action="update_open_enrollment_dates"
# RAILS_ENV=production bundle exec rake migrations:UpdateFehbOeDatesAndContributionCap feins='042266782 042919603 593832832' effective_on=01/01/2020 employee_only_cap=510.84 employee_plus_one_cap=1092.26 family_cap=1184.02 action="update_contribution_cap"
# RAILS_ENV=production bundle exec rake migrations:UpdateFehbOeDatesAndContributionCap feins='042266782 042919603 593832832' effective_on=01/01/2020 action="begin_open_enrollment"

namespace :migrations do
  desc "updating open enrollment dates and contribution cap for fehb draft planyear"
  UpdateFehbOeDatesAndContributionCap.define_task :UpdateFehbOeDatesAndContributionCap => :environment
end
