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

      def enrollment_transition_date(enrollment, aasm_state)
        enrollment.workflow_state_transitions.detect{|state| state.to_state == aasm_state }.transition_at.to_date
      end

      def plan_year_matched?(cancelled_enr, waived_enr)
        cancelled_enr.benefit_group.plan_year == waived_enr.benefit_group.plan_year
      end

      def transition_matched?(cancelled_enr, waived_enr)
        enrollment_transition_date(cancelled_enr, "coverage_canceled") == enrollment_transition_date(waived_enr, "inactive")
      end

      def waived_enrollments(hbx_enrollments)
        hbx_enrollments.where(aasm_state: "inactive")
      end

      def canceled_enrollments(hbx_enrollments)
        cancelled_enrs = []
        hbx_enrollments.where(aasm_state: "coverage_canceled").each do |enrollment|
          transition_date = enrollment_transition_date(enrollment, "coverage_canceled")
          if enrollment.effective_on < transition_date
            cancelled_enrs << enrollment
          end
        end

        cancelled_enrs
      end

      def canceled_waived_enrollments(hbx_enrollments)
        enrollment_pairs = []

        canceled_enrs = canceled_enrollments(hbx_enrollments)
        waived_enrs = waived_enrollments(hbx_enrollments)

        if canceled_enrs.present? && waived_enrs.present?
          canceled_enrs.each do |cancelled_enr|
            waived_enrs.each do |waived_enr|
              if plan_year_matched?(cancelled_enr, waived_enr) && transition_matched?(cancelled_enr, waived_enr)
                enrollment_pairs << [waived_enr, cancelled_enr]
              end
            end
          end
        end

        enrollment_pairs
      end

      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

  			Person.all_employee_roles.each do |person|
          begin
            if person.primary_family.present?
              hbx_enrollments = person.primary_family.active_household.hbx_enrollments
              next if hbx_enrollments.size < 2
              canceled_waived_pairs = canceled_waived_enrollments(hbx_enrollments)

              if canceled_waived_pairs.present?
                canceled_waived_pairs.each do |cancelled_waived_pair|
                  csv << [
                    person.hbx_id,
                    person.full_name,
                    cancelled_waived_pair[0].hbx_id,
                    cancelled_waived_pair[1].hbx_id,
                  ]
                end
                processed_count = processed_count + 1
              end
            end
          rescue Exception => e
            Rails.logger.error {"Bad Person record #{person.hbx_id} due to #{e}"} unless Rails.env.test?
          end
        end
        puts "File path: %s, No. of EE's with waived enrollment tiles %d." %[file_path, processed_count]
      end
    end
  end
end
