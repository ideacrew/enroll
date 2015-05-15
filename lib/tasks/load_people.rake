namespace :seed do
  desc "Load the people data"
  task :people => :environment do
    Person.delete_all
    file = File.open("db/seedfiles/people.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)
    puts "Loading #{data.count} people."
    num_success = data.reduce(0) do |acc, pd|
      begin
      person = Person.create!(pd)
      rescue
        raise pd.inspect
      end
      person.valid? ? acc + 1 : acc
    end
    puts "Loaded #{num_success} people successfully."
  end

  desc "Load the family data"
  task :families => :environment do
    Family.delete_all
    file = File.open("db/seedfiles/heads_of_families.json")
    heads_of_family = JSON.load(file.read)
    file.close
    families_built = 0
    Person.each do |person|
      if heads_of_family.include?(person.id.to_s)
        Family.new.build_from_person(person).save!
        families_built = families_built + 1
      end
    end
    puts "Loaded #{families_built} families successfully"
=begin
    file = File.open("db/seedfiles/families.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)
    puts "Loading #{data.count} families."
    num_success = data.reduce(0) do |acc, pd|
      family = Family.create(pd)
      family.valid? ? acc + 1 : acc
    end
    puts "Loaded #{num_success} families successfully."
=end
  end
end
