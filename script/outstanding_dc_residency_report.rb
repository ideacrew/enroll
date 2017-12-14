require "csv"
include VerificationHelper
CSV.open("outstanding_dc_residency_report.csv", "wb") do |csv_out|
  csv_out << ["HBX ID", "FIRST NAME", "LAST NAME", "DUE DATE"]
  Person.all_consumer_roles.each do |person|
    begin
      family = person.primary_family
      if family.present?
        family.family_members.active.each do |family_member|
          person = family_member.person rescue nil
          person.verification_types.select {|v_type| v_type == "DC Residency"}.each do |v_type|
            if type_unverified?(v_type, person) && family_member.is_applying_coverage
              due_date = "N/A"
              if can_show_due_date?(person)
                if (person.primary_family.min_verification_due_date || TimeKeeper.date_of_record + 95.days) <= TimeKeeper.date_of_record
                  due_date = person.primary_family.min_verification_due_date_on_family
                else
                  due_date = (person.primary_family.min_verification_due_date || TimeKeeper.date_of_record + 95.days)
                end
              end if person.primary_family.present?
              row = []
              row << person.hbx_id
              row << person.first_name
              row << person.last_name
              row << due_date
              csv_out << row
            end
          end if person.present?
        end
      end
    rescue => e
      puts "Error => #{e.inspect}"
    end
  end
end