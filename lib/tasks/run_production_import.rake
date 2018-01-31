namespace :production do

  desc "Seed the production database"
  task :seed => :environment do
=begin
    Rake::Task["db:mongoid:purge"].invoke
    Rake::Task["db:mongoid:drop"].invoke
    Rake::Task["db:mongoid:remove_indexes"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
    require File.join(Rails.root, "db/seedfiles/qualifying_life_event_kinds_seed")
    require File.join(Rails.root, "db/seedfiles/carriers_seed")
    Rake::Task["seed:plans"].invoke
    Rake::Task["xml:serff"].invoke("XML")
    require File.join(Rails.root, "db/seedfiles/shop_2015_sbc_files")
#    Rake::Task["seed:broker_json"].invoke
    #
    Rake::Task["seed:people"].invoke
    Rake::Task["seed:families"].invoke
=end
#    Rake::Task["hbx:employers:add"].invoke("tmp/employers.csv","db/seedfiles/blacklist.csv")
    Rake::Task["hbx:employers:census:add"].invoke("tmp/census.csv")
    require File.join(Rails.root, "db/seedfiles/admins_seed")
    require File.join(Rails.root, "db/seedfiles/slcsp_seed")
  end

end
