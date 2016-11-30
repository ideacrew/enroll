require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class PrimarySubscribersDataWithECaseId < MongoidMigrationTask
  def migrate
    field_names  = %w(
          Integrated_Case_ID_(e_case_id)
          Subscriber_FN
          Subscriber_LN
          HBX_ID
          SSN
          DOB
          Gender
          Primary_Person_Record_Create_Date
          Type
         )
       count = 0
       file_name = "#{Rails.root}/public/primary_subscribers_data_with_e_case_id.csv"
 
      CSV.open(file_name, "w", force_quotes: true) do |csv|
         csv << field_names
         families = Family.where(:e_case_id.nin => ["", nil]).to_a

         families.each do |family|
          begin
            person = family.primary_family_member.person
          
            csv << [
              family.e_case_id,
              person.first_name,
              person.last_name,
              person.hbx_id,
              person.ssn,
              person.dob,
              person.gender,
              person.created_at,
              "Primary"
             ]
             
             family.dependents.each do |dependent|
              dependent_person = dependent.person
              csv << [
                  family.e_case_id,
                  dependent_person.first_name,
                  dependent_person.last_name,
                  dependent_person.hbx_id,
                  dependent_person.ssn,
                  dependent_person.dob,
                  dependent_person.gender,
                  dependent_person.created_at,
                  "Dependent"
              ]

             end
            count += 1
          rescue
            puts "Bad Family record with id: #{family.id}"
          end
        end
      end
      puts "Total number of families with e_case_id: #{count}"
      
  end

end