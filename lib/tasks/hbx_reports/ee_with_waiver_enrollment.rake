# Report: Rake task to Produce Report of EEs with Waiver Tiles
# Run this task every Month: RAILS_ENV=production bundle exec rake reports:shop:ee_with_waiver_enrollment

require 'csv'
 
namespace :reports do
  namespace :shop do

    desc "employee's with waived enrollment tiles"
    task :ee_with_waiver_enrollment, [:file] => :environment do

      field_names  = %w(
        HBX_ID
        FULL_NAME
        WAIVED_ENROLLMENT_ID
        CANCELED_ENROLLMENT_ID
      )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/ee_with_waiver_enrollment.csv"
      
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

  			Person.all_employee_roles.each do |person|
          begin
            if person.primary_family.present? && person.primary_family.households.first.hbx_enrollments.count > 1
              hbx_enrollments = person.primary_family.households.first.hbx_enrollments
              aasm_states = hbx_enrollments.map(&:aasm_state)
              if (aasm_states.include? "coverage_canceled") && (aasm_states.include? "inactive" || "renewing_waived")
                waived_enrollment = hbx_enrollments.where(aasm_state: "inactive" || "renewing_waived").first
                waived_plan_year = waived_enrollment.benefit_group.plan_year.id.to_s
                hbx_enrollments.where(aasm_state: "coverage_canceled").each do |canceled_enrollment|
                  if waived_plan_year == canceled_enrollment.benefit_group.plan_year.id.to_s
                    if canceled_enrollment.workflow_state_transitions.where(to_state: 'coverage_canceled').first.transition_at.to_date == waived_enrollment.workflow_state_transitions.where(to_state: 'inactive').first.transition_at.to_date
                      csv << [
                        person.hbx_id,
                        person.full_name,
                        waived_enrollment.id,
                        canceled_enrollment.id,
                      ]
                    end
                  end
                end
              end
            processed_count +=1
            end
          rescue
            puts "Bad Person record #{person.hbx_id}"
          end
        end
        puts "File path: %s, No. of EE's with waived enrollment tiles %d." %[file_path, processed_count]
      end
    end
  end
end
