require File.join(Rails.root, "app", "data_migrations", "correct_citizen_with_ssn")

namespace :migrations do
  desc "Correct citizen with SSN and existing response"
  CorrectCitizenStatus.define_task :correct_citizen_with_ssn => :environment
end