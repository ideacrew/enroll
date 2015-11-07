namespace :congress do

  desc "Seed the production database"
  task :load_roster => :environment do
    Rake::Task["hbx:employers:census:add"].invoke("tmp/congress_census.csv")
  end

end
