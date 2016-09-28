require 'csv'
namespace :reports do
  namespace :shop do
    desc "All Individual that has uploaded files without being approved"
    task :individual => :environment do
      people = Person.where(:consumer_role.exists=>true,"consumer_role.aasm_state"=>"ssa_pending")
      field_names  = %w(
          First_Name
          Last_Name
        )
      file_name = "#{Rails.root}/public/individual.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        people.each do |person|
          csv << [
              person.first_name,
              person.last_name
              ]
        end
      end
    end
  end
end