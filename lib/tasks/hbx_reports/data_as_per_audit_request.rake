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
         Primary_Applicant_Indicator
         Home_Address_line_1
         Home_Address_line_2
         Home_City
         Home_State
         Home_Zipcode
         Mailing_Address_line_1
         Mailing_Address_line_2
         Mailing_City
         Mailing_State
         Mailing_Zipcode
         Citizenship_Status
         Naturalized_Citizen
         Incarceration_Status
         American_Indian_Or_Alaska_Native
       )
     count = 0
     file_name = "#{Rails.root}/public/audit_request_data_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      families = Family.by_enrollment_effective_date_range(Date.new(2016,1,1), Date.new(2016,12,31)).where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}, :"e_case_id" => nil, :"households.hbx_enrollments.kind" => "individual", :"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::CANCELED_STATUSES || (HbxEnrollment::TERMINATED_STATUSES - ["unverified", "void"])))
      families.each do |family|
        begin
          primary_fm = family.primary_family_member
          next if primary_fm.person.user.blank?
          next if family.households.flat_map(&:hbx_enrollments).any? {|enr| enr.effective_on < Date.new(2016,1,1)}
          family.family_members.each do |fm|
            begin
              enrollments = primary_fm.family.active_household.try(:hbx_enrollments)
              health_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "health").first if enrollments.present?
              dental_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "dental").first if enrollments.present?
              
              health_enrollment = if health_enr.present? && fm.is_primary_applicant
                                    health_enrollmnt_kind(health_enr)
                                  elsif health_enr.present? && !fm.is_primary_applicant
                                    health_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? health_enrollmnt_kind(health_enr) : "No Health Enrollment"
                                  else
                                    "No Active Health Enrollment"
                                  end

              dental_enrollment = if dental_enr.present? && fm.is_primary_applicant
                                    dental_enrollmnt_kind(dental_enr)
                                  elsif dental_enr.present? && !fm.is_primary_applicant
                                    dental_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? dental_enrollmnt_kind(dental_enr) : "No Dental Enrollment"
                                  else
                                    "No Active Dental Enrollment"
                                  end

              mailing_address = fm.person.addresses.detect { |adr| adr.kind == "mailing" }
              citizen_status = fm.person.citizen_status.try(:humanize) || (fm.person.citizen_status.try(:humanize) if !fm.is_primary_applicant ) || "No Info"
              naturalized_citizen = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS.include?(fm.person.citizen_status) if fm.person.citizen_status.present?
              tribe_member = ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS.include?(fm.person.citizen_status) if fm.person.citizen_status.present?

              csv << [
                fm.family.hbx_assigned_id,
                fm.person.hbx_id,
                fm.person.last_name,
                fm.person.first_name,
                fm.person.full_name,
                fm.person.dob,
                fm.primary_relationship,
                submitted_app_primary.addresses[0].created_at,
                health_enrollment,
                dental_enrollment,
                fm.person.gender,
                fm.is_primary_applicant,
                fm.person.home_address.try(:address_1),
                fm.person.home_address.try(:address_2),
                fm.person.home_address.try(:city),
                fm.person.home_address.try(:state),
                fm.person.home_address.try(:zip),
                mailing_address.try(:address_1),
                mailing_address.try(:address_2),
                mailing_address.try(:city),
                mailing_address.try(:state),
                mailing_address.try(:zip),
                citizen_status,
                naturalized_citizen,
                fm.person.is_incarcerated,
                tribe_member
              ]
              count += 1
            rescue => e
              puts "Bad family member record with family id: #{fm.family.id}. Exception: #{e}"
            end
          end
        rescue => e
          puts "#{e}"
        end
      end
    end
    puts "Total person's that are created in a time frame of #{start_date}-#{end_date} count is #{count}"
  end

  def health_enrollmnt_kind(health_enr)
    health_enr.kind == "employer_sponsored" ? "SHOP" : (health_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
  end

  def dental_enrollmnt_kind(dental_enr)
    dental_enr.kind == "employer_sponsored" ? "SHOP" : (dental_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
  end
end
