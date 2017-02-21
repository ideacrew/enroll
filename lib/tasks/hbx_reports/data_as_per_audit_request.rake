require 'csv'
 # This is a report that generated for audit purpose, with IVL's not applied for assistance.
 # The task to run is RAILS_ENV=production bundle exec rake reports:audit_requested_list
namespace :reports do
 
  desc "List of unassisted IVL's registered in enroll from 10/12/2015 to 10/31/2016"
  task :audit_requested_list => :environment do

    start_date = Date.new(2015,10,12)
    end_date = Date.new(2016,9,30)

     field_names  = %w(
         FAMILY_ID
         HBX_ID
         Last_Name
         First_Name
         Full_Name
         Date_Of_Birth
         Relationship
         Application_Date
         Health_Enrollment
         Dental_Enrollment
         Gender
         Home_Phone_Number
         Work_Phone_Number
         Cell_Number
         Home_Email_Address
         Work_Email_Address
         Primary_Applicant_Indicator
         Home_Address_line_1
         Home_Address_line_2
         Home_City
         Home_State
         Home_Zipcode
         Ethnicity
         Mailing_Address_line_1
         Mailing_Address_line_2
         Mailing_City
         Mailing_State
         Mailing_Zipcode
         Citizenship_Status
         Naturalized_Citizen
         Incarceration_Status
         Employment_Status
         American_Indian_Or_Alaska_Native
         Documents
       )
     count = 0
     file_name = "#{Rails.root}/public/audit_request_data_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      families = Family.where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}, :"e_case_id" => nil)
      families.each do |family|
        begin
          primary_fm = family.primary_family_member
          if primary_fm.person.consumer_role.present?
            family.family_members.each do |fm|
              begin
                enrollments = primary_fm.family.active_household.try(:hbx_enrollments)
                health_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "health").first if enrollments.present?
                dental_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "dental").first if enrollments.present?
                
                health_enrollment = if health_enr.present? && fm.is_primary_applicant
                                      health_enr.kind == "employer_sponsored" ? "SHOP" : (health_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
                                    elsif health_enr.present? && !fm.is_primary_applicant
                                      health_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? "Covered Under Primary" : "No Health Enrollment"
                                    else
                                      "No Active Health Enrollment"
                                    end

                dental_enrollment = if dental_enr.present? && fm.is_primary_applicant
                                      dental_enr.kind == "employer_sponsored" ? "SHOP" : (dental_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
                                    elsif dental_enr.present? && !fm.is_primary_applicant
                                      dental_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? "Covered Under Primary" : "No Dental Enrollment"
                                    else
                                      "No Active Dental Enrollment"
                                    end
                mailing_address = fm.person.addresses.detect { |adr| adr.kind == "mailing" }
                citizen_status = fm.person.citizen_status.try(:humanize) || "No Info"
                naturalized_citizen = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS.include?(fm.person.citizen_status) if fm.person.citizen_status.present?
                employment_status = fm.person.active_employee_roles.present? ? "Employed" : "Not Employed"
                tribe_member = ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS.include?(fm.person.citizen_status) if fm.person.citizen_status.present?

                csv << [
                  fm.family.hbx_assigned_id,
                  fm.hbx_id,
                  fm.last_name,
                  fm.first_name,
                  fm.person.full_name,
                  fm.dob,
                  fm.primary_relationship,
                  fm.family.created_at,
                  health_enrollment,
                  dental_enrollment,
                  fm.gender,
                  fm.person.home_phone,
                  fm.person.work_phone,
                  fm.person.mobile_phone,
                  fm.person.home_email.try(:address),
                  fm.person.work_email.try(:address),
                  fm.is_primary_applicant,
                  fm.person.home_address.try(:address_1),
                  fm.person.home_address.try(:address_2),
                  fm.person.home_address.try(:city),
                  fm.person.home_address.try(:state),
                  fm.person.home_address.try(:zip),
                  fm.person.ethnicity,
                  mailing_address.try(:address_1),
                  mailing_address.try(:address_2),
                  mailing_address.try(:city),
                  mailing_address.try(:state),
                  mailing_address.try(:zip),
                  citizen_status,
                  naturalized_citizen,
                  fm.person.is_incarcerated,
                  employment_status,
                  tribe_member,
                  fm.person.consumer_role.vlp_documents.pluck(:verification_type).uniq
                ]
                count += 1
              rescue
                puts "Bad family member record with family id: #{fm.family.id}"
              end
            end
          end
        rescue
          puts "Bad family record with id: #{family.id}"
        end
      end
    end
    puts "Total person's that are created in a time frame of #{start_date}-#{end_date} count is #{count}"
  end
end
