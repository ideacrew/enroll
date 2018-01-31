require File.join(Rails.root, "app", "data_migrations", "correct_non_citizen_with_ssn")

namespace :migrations do
  desc "Correct NON citizen with SSN and existing response"
  CorrectNonCitizenStatus.define_task :correct_non_citizen_with_ssn => :environment
end