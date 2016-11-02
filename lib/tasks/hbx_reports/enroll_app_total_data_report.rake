require 'csv'
# This is a one-time report
# The task to run is RAILS_ENV=production rake reports:people:total_people_list
 namespace :reports do
   namespace :people do
 
     desc "List of all people in the enroll database"
     task :total_people_list => :environment do

      today = TimeKeeper.date_of_record
 
       field_names  = %w(
           HBX_ID
           Last_Name
           First_Name
           Date_Of_Birth
           SSN
           Application_Date
           Applied_For_Assistance
           Max_APTC
           CSR_percentage
           Gender
           Home_Phone_Number
           Work_Phone_Number
           Cell_Number
           Home_Email_Address
           Work_Email_Address
           Primary_Applicant_Indicator
           Address_line_1
           Address_line_2
           City
           State
           Zipcode
           Ethnicity
         )
       count = 0
       file_name = "#{Rails.root}/public/enroll_app_total_data_report.csv"
 
      CSV.open(file_name, "w", force_quotes: true) do |csv|
         csv << field_names
 
        Person.all.each do |person|
          begin
            family_member = person.try(:primary_family).try(:family_members).where(person_id: person.id).try(:first) if person.try(:primary_family).try(:family_members).present?
            is_applied_for_assistance = person.try(:primary_family).try(:e_case_id).present? ?  "Yes" : "No"
            csv << [
              person.hbx_id,
              person.last_name,
              person.first_name,
              person.dob,
              person.ssn,
              person.created_at,
              is_applied_for_assistance,
              person.try(:primary_family).try(:active_household).try(:latest_active_tax_household).try(:latest_eligibility_determination).try(:max_aptc),
              person.try(:primary_family).try(:active_household).try(:latest_active_tax_household).try(:latest_eligibility_determination).try(:csr_percent_as_integer),
              person.gender,
              person.home_phone,
              person.work_phone,
              person.mobile_phone,
              person.home_email.try(:address),
              person.work_email.try(:address),
              family_member.try(:is_primary_applicant),
              person.home_address.try(:address_1),
              person.home_address.try(:address_2),
              person.home_address.try(:city),
              person.home_address.try(:state),
              person.home_address.try(:zip),
              person.ethnicity
             ]
            count += 1
          rescue
            puts "Bad Person record with id: #{person.id}"
          end
        end
      end
      puts "Total person's count in enroll database till #{today} is #{count}"
     end
   end
 end
