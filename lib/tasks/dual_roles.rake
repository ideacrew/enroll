require 'csv'

namespace :reports do
  namespace :dual do
    desc "All Users"
    task :persons => :environment do

      field_names  = %w(
          first_name
          last_name
          hbx_id
          is_consumer_role_active
          is_employee_role_active
          roles
        )

 file_name = "#{Rails.root}/public/persons_roles.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        Person.all.to_a.each do |person|
            if person.consumer_role.present? && person.active_employee_roles.any?
              roles = person.user.roles.join(",") if person.user.present?
              csv << [
                "#{person.first_name}","#{person.last_name}","#{person.hbx_id}", "#{Person.person_has_an_active_enrollment?(person)}", "#{person.has_active_employee_role?}", "#{roles}"     ]
            end
          end
       end
    end
  end
end
