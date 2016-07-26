# Rake task to find ivl, census employee's who terminated their hbx_enrollment in date range [start_end..end_date]
# To Run Rake Task: RAILS_ENV=production rake reports:ivl_employee:termination_submitted_on[start_date,end_date]
# date_format:RAILS_ENV=production rake reports:ivl_employee:termination_submitted_on[%d/%m/%Y,%d/%m/%Y]
require 'csv'

namespace :reports do
  namespace :ivl_employee do

    desc "List of ivl and census employee's terminated their hbx_enrollment"
    task :termination_submitted_on, [:start_date, :end_date] => [:environment] do |task, args|

      start_date = Date.parse(args[:start_date]).beginning_of_day
      end_date = Date.parse(args[:end_date]).end_of_day
      termination_submitted_on = start_date..end_date

      families = Family.where(:"households.hbx_enrollments" =>{ :$elemMatch => {:"aasm_state" => "coverage_terminated",
                                                                            :"updated_at" => termination_submitted_on}})
      field_names  = %w(
               HBX_ID
               Enrolled_Member_First_Name
               Enrolled_Member_Last_Name
               Employer_Legal_Name
               Fein
               Primary_Member_First_Name
               Primary_Member_Last_Name
               Market_Kind
               Plan_Name
               HIOS_ID
               Policy_ID
               Effective_Start_Date
               End_Date
               Termination_Submitted_On
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/ivl_employee_termination_submitted_on_report.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        families.each do |family|
          hbx_enrollments = [family].flat_map(&:households).flat_map(&:hbx_enrollments).select{|hbx| hbx.aasm_state == "coverage_terminated" && termination_submitted_on.cover?(hbx.updated_at)}
          hbx_enrollment_members = hbx_enrollments.flat_map(&:hbx_enrollment_members)
          hbx_enrollment_members.each do |hbx_enrollment_member|
            if hbx_enrollment_member
              csv << [
                  hbx_enrollment_member.person.hbx_id,
                  hbx_enrollment_member.person.first_name,
                  hbx_enrollment_member.person.last_name,
                  family.primary_family_member.person.try(:active_employee_roles).try(:first).try(:employer_profile).try(:legal_name),
                  family.primary_family_member.person.try(:active_employee_roles).try(:first).try(:employer_profile).try(:fein),
                  family.primary_family_member.person.first_name,
                  family.primary_family_member.person.last_name,
                  hbx_enrollment_member.hbx_enrollment.kind,
                  hbx_enrollment_member.hbx_enrollment.plan.name,
                  hbx_enrollment_member.hbx_enrollment.plan.hios_id,
                  hbx_enrollment_member.hbx_enrollment.hbx_id,
                  hbx_enrollment_member.hbx_enrollment.effective_on,
                  hbx_enrollment_member.hbx_enrollment.terminated_on,
                  hbx_enrollment_member.hbx_enrollment.updated_at
              ]
            end
            processed_count += 1
          end
        end
        puts "For date range  #{termination_submitted_on}, total ivl and census employee's terminated their hbx_enrollment count #{processed_count} and information output file: #{file_name}"
      end
    end
  end
end