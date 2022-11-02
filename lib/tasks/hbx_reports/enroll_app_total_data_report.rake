require 'csv'
# This is a one-time report
# The task to run is RAILS_ENV=production rake reports:people:total_people_list
 namespace :reports do
   namespace :people do
 
     desc "List of all people in the enroll database"
     task :total_people_list => :environment do

      today = TimeKeeper.date_of_record
 
       field_names  = %w(
           FAMILY_ID
           HBX_ID
           Last_Name
           First_Name
           Date_Of_Birth
           SSN
           Relationship
           Application_Date
           Applied_For_Assistance
           Max_APTC
           CSR_percentage
           Is_Medicaid_Chip_Eligible
           Health_Enrollment
           Dental_Enrollment
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
 
        Family.all.each do |family|
          primary_fm = family.primary_family_member
          if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
            tax_household_group = family.tax_household_groups.active.first
            tax_households = tax_household_group&.tax_households
            tax_household_members = tax_households.map(&:tax_household_members).flatten if tax_households
          else
            tax_household_members = family.active_household&.latest_active_tax_household&.tax_household_members
          end

          family.family_members.each do |fm|
            begin
              if tax_household_group.present?
                tax_household_member = tax_household_members.detect { |thm| thm.applicant_id.to_s == fm.id.to_s }
                is_medicaid_chip_eligible = tax_household_member&.is_medicaid_chip_eligible ? "Yes" : "No"
                is_applied_for_assistance = tax_household_member.present? ? "Yes" : "No"
                max_aptc = tax_households.sum { |thh| thh.max_aptc.to_f }
                csr_eligibility_kind = tax_household_member&.csr_eligibility_kind
              end

              unless EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                tax_household_member = tax_household_members.detect {|thm| thm.person.id == fm.person.id } if tax_household_members.present?
                is_medicaid_chip_eligible = tax_household_member&is_medicaid_chip_eligible ? "Yes" : "No"
                is_applied_for_assistance = tax_household_member.present? ?  "Yes" : "No"
                latest_eligibility_determination = family.active_household&.latest_active_tax_household&.latest_eligibility_determination
                max_aptc = latest_eligibility_determination&.max_aptc
                csr_eligibility_kind = latest_eligibility_determination&.csr_percent_as_integer
              end

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

              csv << [
                fm.family.hbx_assigned_id,
                fm.hbx_id,
                fm.last_name,
                fm.first_name,
                fm.dob,
                fm.ssn,
                fm.primary_relationship,
                fm.family.created_at,
                is_applied_for_assistance || 'No',
                max_aptc || 0.0,
                csr_eligibility_kind,
                is_medicaid_chip_eligible || 'No',
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
                fm.person.ethnicity
              ]
              count += 1
            rescue
              puts "Bad family record with id: #{fm.family.id}"
            end
          end
        end
      end
      puts "Total person's count in enroll database till #{today} is #{count}"
     end
   end
 end
