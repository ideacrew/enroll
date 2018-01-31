namespace :premiums do
  desc "cache premiums plan for fast group fetch"
  task :reload => :environment do 
    Plan.all.each do |plan|
      plan.reload_premium_cache
      print '.'
    end
  end
end
