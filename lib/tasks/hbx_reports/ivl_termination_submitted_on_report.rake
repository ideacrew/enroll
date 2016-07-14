# Daily Report: Rake task to find IVL users who submitted termination on previous date
# To Run Rake Task: RAILS_ENV=production rake reports:ivl:terminations_submitted_on
require 'csv'

namespace :reports do
  namespace :ivl do

    desc "List of IVL submitted terminations yesterday "
    task :terminations_submitted_on => :environment do

      date_of_termination=Date.yesterday.beginning_of_day..Date.yesterday.end_of_day
      # find families who terminated their hbx_enrollments
      families = Family.where(:"households.hbx_enrollments" =>{ :$elemMatch => {:"aasm_state" => "coverage_terminated",
                                                                                :"updated_at" => date_of_termination}})
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
               Termination_Submitted_On
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/ivl_terminations_submitted_report.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        families.each do |family|
          # reject if doesn't have consumer role
          next unless family.primary_family_member.person.consumer_role
          # find hbx_enrollments who's aasm state=coverage_terminated and updated i.e submitted date == previous day
          hbx_enrollments = [family].flat_map(&:households).flat_map(&:hbx_enrollments).select{|hbx| hbx.aasm_state == "coverage_terminated" && hbx.updated_at.strftime('%Y-%m-%d') == Date.yesterday.strftime('%Y-%m-%d')}
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
                  hbx_enrollment.terminated_on,
                  hbx_enrollment.updated_at
              ]
            end
            processed_count += 1
          end
        end
        puts "For date #{Date.yesterday}, Total IVL termination count #{processed_count} and IVL information output file: #{file_name}"
      end
    end
  end
end