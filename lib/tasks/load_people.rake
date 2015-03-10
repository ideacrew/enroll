namespace :seed do
  desc "Load the people data"
  task :people => :environment do
    Person.delete_all
    plan_file = File.open("db/seedfiles/people.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Person.create!(pd)
    end
  end

  desc "Load the family data"
  task :families => :environment do
    Family.delete_all
    plan_file = File.open("db/seedfiles/families.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Family.create!(pd)
    end
  end
end
