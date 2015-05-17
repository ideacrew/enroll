namespace :production do

  desc "Seed the production database"
  task :seed => :environment do
    Rake::Task["db:mongoid:drop"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
    Rake::Task["seed:plans"].invoke
    Rake::Task["xml:serff"].invoke("XML")
    Rake::Task["seed:people"].invoke
    Rake::Task["seed:families"].invoke
  end
  
end
