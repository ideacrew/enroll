 require 'csv'
 # This will generate a csv file containing primary subscribers of EA associated with integrated case.
 # The task to run is RAILS_ENV=production bundle exec rake reports:primary_subscriber:with_e_case_id
 namespace :reports do
   namespace :primary_subscriber do
 
     desc "List of all Primary Subscribers in Enroll with an associated integrated case"
     task :with_e_case_id => :environment do

 
       field_names  = %w(
          Integrated_Case_ID_(e_case_id)
          Subscriber_FN
          Subscriber_LN
          HBX_ID
          SSN
          DOB
          Gender
          Primary_Person_Record_Create_Date
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
              person.created_at
             ]
            count += 1
          rescue
            puts "Bad Person record with id: #{person.id}"
          end
        end
      end
      puts "Total number of families with e_case_id: #{count}"
     end
   end
 end
