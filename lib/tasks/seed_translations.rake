namespace :seed do
  desc "load translations from the specified file"
  task :translations, [:file] => [:environment] do |t, args|
    puts "Seeding #{args[:file]}"
    require File.join(Rails.root, args[:file][0..-4])
  end
end
