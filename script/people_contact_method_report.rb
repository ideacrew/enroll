# frozen_string_literal: true

require 'csv'
people_field_names = %w[FirstName LastName HbxID Role ContactMethod]
people_file_name = "#{Rails.root}/people_role_contact_method_report#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
puts "Start of rake, time: #{Time.zone.now}"
CSV.open(people_file_name, 'w', force_quotes: true) do |csv|
  csv << people_field_names
  Person.all_consumer_roles.pluck(:first_name, :last_name, :hbx_id, :"consumer_role.contact_method").inject([]) do |tt, result_set|
    begin
      csv << [result_set[0],
              result_set[1],
              result_set[2],
              'Consumer Role',
              result_set[3]["contact_method"]]
    rescue => e
      puts "ConsumerRole, Message: #{e.message}"
    end
    tt
  end

  Person.all_resident_roles.pluck(:first_name, :last_name, :hbx_id, :"resident_role.contact_method").inject([]) do |tt, result_set|
    begin
      csv << [result_set[0],
              result_set[1],
              result_set[2],
              'Resident Role',
              result_set[3]["contact_method"]]
    rescue => e
      puts "ResidentRole, Message: #{e.message}"
    end
    tt
  end

  Person.all_employee_roles.inject([]) do |tt, person|
    begin
      person.employee_roles.each do |ee_role|
        csv << [person.first_name,
                person.last_name,
                person.hbx_id,
                'Employee Role',
                ee_role.contact_method]
      end
    rescue => e
      puts "EmployeeRole, Message: #{e.message}"
    end
    tt
  end
end
puts "End of rake, time: #{Time.zone.now}"
