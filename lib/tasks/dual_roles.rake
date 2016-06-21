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
          Roles
        )

 file_name = "#{Rails.root}/public/persons_roles.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        Person.all.to_a.each do |person|
          census_employee = CensusEmployee.where(first_name: person.first_name, last_name: person.last_name, dob: person.dob).first
            if census_employee.present?
             role_status = census_employee.active_benefit_group_assignment.try(:is_active)
            else
             if person.has_active_employee_role?
              role_status = true
              else
              role_status = false
            end
            end

            if person.primary_family.present?
              has_benefit_group = person.primary_family.active_household.try(:hbx_enrollments).each do |hbx|
              break false if hbx.benefit_group_assignment.blank? && hbx==person.primary_family.active_household.hbx_enrollments.last
              next if hbx.benefit_group_assignment.blank?
              break true if hbx.benefit_group_assignment.present?
            end
            else
              has_benefit_group = false
            end

            if person.user.present?
             roles = person.user.roles
            else
             roles = "no user"
            end

            if Person.person_has_an_active_enrollment?(person) && (has_benefit_group || person.employee_roles.present?)
              csv << [
                "#{person.first_name}","#{person.last_name}","#{person.hbx_id}", "#{Person.person_has_an_active_enrollment?(person)}", "#{role_status}", "#{roles}"
                     ]
            end
         end
       end
    end
  end
end
