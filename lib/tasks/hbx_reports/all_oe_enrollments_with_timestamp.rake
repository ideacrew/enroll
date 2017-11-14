#this rake task produces an csv report providing all OE enrollments have a timestamp
#to be an active OE IVL enrollment:
#1)special enrollment perid should be nil
#2)market type is individual
#3)workflow state transitions should not include auto_renewing
#4)effective on the first day of current year

require 'csv'
namespace :reports do
  namespace :individual do
    desc "All OE Enrollments that have timestamp"
    task :enrollments_with_timestamp => :environment do
      families = Family.by_enrollment_individual_market.all_enrollments.all
      field_names  = %w(primary_first_name
                        primary_last_name
                        primary_dob
                        primary_ssn
                        plan_selected
                        plan_type
                        plan_metal_level
                        submitted_at
                        )
      processed_count = 0
      file_name = "#{Rails.root}/enrollments_with_timestamp.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        families.each do |family|
          enrollments=family.active_household.hbx_enrollments.where({:"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES}).all
          unless enrollments.nil?
            enrollments.each do |enrollment|
              csv << [
                  family.primary_applicant.person.first_name,
                  family.primary_applicant.person.last_name,
                  family.primary_applicant.person.dob,
                  family.primary_applicant.person.ssn,
                  enrollment.plan.name,
                  enrollment.plan.plan_type,
                  enrollment.plan.metal_level,
                  enrollment.submitted_at
                ]
              processed_count += 1
              if processed_count % 500 ==0
                puts "#{processed_count}" unless Rails.env.test?
              end
            end
          end
        end
      end
    end
  end
end