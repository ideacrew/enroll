require 'csv'
 
 namespace :reports do
   namespace :ivl do
 
     desc "List of IVL terminations for today"
     task :terminations_report => :environment do
 
       date_of_termination = TimeKeeper.date_of_record.yesterday
 
       families = Family.where(:"households.hbx_enrollments" =>
       	  { :$elemMatch => {
           :"aasm_state" => "coverage_terminated",
           :"terminated_on" => date_of_termination }
       	  })
 
           field_names  = %w(
               HBX_ID
               Last_Name
               First_Name
               SSN
               Plan_Name
               HIOS_ID
               Policy_ID
               Effective_Start_Date
               End_Date
             )
       processed_count = 0
       file_name = "#{Rails.root}/public/ivl_terminations.csv"
 
       CSV.open(file_name, "w", force_quotes: true) do |csv|
         csv << field_names
 
         families.each do |family|
           # reject if doesn't have consumer role
           next unless family.primary_family_member.person.consumer_role
           hbx_enrollments = family.households.first.hbx_enrollments.select{|hbx| hbx.terminated_on && hbx.terminated_on == date_of_termination}
            hbx_enrollments.each do |hbx_enrollment|
              if hbx_enrollment
             csv << [
                 hbx_enrollment.id,
                 family.primary_family_member.person.last_name,
                 family.primary_family_member.person.first_name,
                 family.primary_family_member.person.ssn,
                 hbx_enrollment.plan.name,
                 hbx_enrollment.plan.hios_id,
                 hbx_enrollment.hbx_id,
                 hbx_enrollment.effective_on,
                 hbx_enrollment.terminated_on
             ]
           end
          end
           processed_count += 1
         end
       end
 
     end
   end
 end