namespace :seed do
  desc "Load the people data"
  task :people => :environment do
    Person.delete_all
    plan_file = File.open("db/seedfiles/people.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      per = Person.new(pd)
      Person.create!(pd)
    end
  end
end
