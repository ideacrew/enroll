require 'csv'

#this report generate current IVL and SHOP enrollees from EnrollApp. 
# The task to run is RAILS_ENV=production bundle exec rake reports:enrollapp_report
namespace :reports do
  desc "List of ivl and shop enrollees from EnrollApp"
  task :enrollapp_report => :environment do
    field_names  = %w(
                    primary_person_hbx_id
                    person_hbx_id 
                    enrollment_hbx_id 
                    First_Name 
                    Last_Name 
                    SSN 
                    DOB 
                    Gender 
                    Relationship 
                    Home_Address 
                    Mailing_Address 
                    Work_Email
                    Home_Email 
                    Phone_Number 
                    Broker
                    Race
                    Ethnicity
                    Citizen Status
                    Benefit_Type_Medical_Dental 
                    Plan_Name 
                    HIOS_ID 
                    Plan_Metal_Level 
                    Carrier_Name 
                    Premium_Amount 
                    Premium_Total 
                    Coverage_Start 
                    Coverage_End 
                    Policy_APTC 
                    Policy_Employer_Contribution 
                    Employer_Name 
                    Employer_DBA 
                    Employer_FEIN 
                    Employer_HBX_ID     
                    )
    file_name = "#{Rails.root}/public/enrollapp_enrollment_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      batch_size = 1000
      offset = 0
      enrollments = HbxEnrollment.enrolled
      @total_count = enrollments.count
      while (offset <= @total_count)
        enrollments.offset(offset).limit(batch_size).each do |hbx|
          begin
            p=hbx.subscriber.person       
            hbx.hbx_enrollment_members.each do |member|
                  if hbx.kind == "employer_sponsored" || hbx.kind ==  "employer_sponsored_cobra"
                    csv << [
                            p.hbx_id,
                            member.try(:hbx_id),
                            hbx.hbx_id,
                            p.first_name,
                            p.last_name,
                            p.dob,
                            p.gender,
                            member.primary_relationship,
                            p.home_address.try(:full_address),
                            p.mailing_address.try(:full_address),
                            p.work_email.try(:address),
                            p.home_email.try(:address),
                            p.try(:work_phone),
                            p.primary_family.active_broker_agency_account.try(:legal_name),
                            p.race,
                            p.ethnicity,
                            p.citizen_status,
                            hbx.coverage_kind,
                            hbx.product.title,
                            hbx.product.hios_id,
                            hbx.product.metal_level_kind.to_s,
                            hbx.product.carrier_profile.abbrev,
                            member.try(:premium_amount).try(:fractional).to_f/100,
                            hbx.total_premium,
                            hbx.elected_aptc_pct,
                            hbx.effective_on,
                            hbx.terminated_on,
                            hbx.total_employer_contribution,
                            hbx.employer_profile.legal_name,
                            hbx.employer_profile.dba,
                            hbx.employer_profile.fein,
                            hbx.employer_profile.hbx_id
                          ]
                  else
                    csv << [
                            p.hbx_id,
                            member.try(:hbx_id),
                            hbx.hbx_id,
                            p.first_name,
                            p.last_name,
                            p.dob,
                            p.gender,
                            member.primary_relationship,
                            p.home_address.try(:full_address),
                            p.mailing_address.try(:full_address),
                            p.work_email.try(:address),
                            p.home_email.try(:address),
                            p.try(:main_phone),
                            p.primary_family.active_broker_agency_account.try(:legal_name),
                            p.race,
                            p.ethnicity,
                            p.citizen_status,
                            hbx.coverage_kind,
                            hbx.product.title,
                            hbx.product.hios_id,
                            hbx.product.metal_level_kind.to_s,
                            hbx.product.carrier_profile.abbrev,
                            member.try(:premium_amount).try(:fractional).to_f/100,
                            hbx.total_premium,
                            hbx.elected_aptc_pct,
                            hbx.effective_on,
                            hbx.terminated_on,
                            "NAN",
                            "NAN",
                            "NAN",
                            "NAN",
                            "NAN"
                          ]
                  end 
              end
          rescue => e
            puts "Bad Family Record, error: #{e}" unless Rails.env.test?
          end
        end
        offset = offset + batch_size
        puts "processed #{offset} records" unless Rails.env.test?
      end
      puts "End of the report" unless Rails.env.test?
    end
  end
end
