require 'csv'

namespace :reports do
  namespace :dual do
    desc "All Users"
    task :persons => :environment do

      field_names  = %w(
          first_name
          last_name
          hbx_id
          Is_consumer_role_active
          Is_employee_role_active
        )

 file_name = "#{Rails.root}/public/persons_roles.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        Person.all.to_a.each do |person|
    if person.consumer_role.present? and person.employee_roles.present?
     csv << [
                "#{person.first_name}","#{person.last_name}","#{person.hbx_id}", "#{person.consumer_role.is_active}", "#{person.employee_roles.map(&:is_active)}"
            ]
    end
end

       

      end
   end
  end
end
