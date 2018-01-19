require File.join(Rails.root, "app", "data_migrations", "correct_decertified_agencies")

namespace :migrations do
  desc "Correct decertified general agencies"
  CorrectDecertifiedAgency.define_task :correct_decertified_agencies => :environment
end