namespace :seed do
  task :single => :environment do
    filename = File.join(Rails.root, 'db', 'seedfiles', "#{ENV['SEED']}.rb")
    puts "Seeding #{filename}..."
    require filename if File.exist?(filename)
  end
end
