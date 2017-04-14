
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearEffectiveDate < MongoidMigrationTask
  def migrate
    begin
      organizations = Organization.where(fein: ENV['fein'])
      state = ENV['aasm_state'].to_s
      start_on = Date.strptime((ENV['py_new_start_on']).to_s, "%m/%d/%Y")
      hios_id = ENV['referenece_plan_hios_id']
      ref_plan_active_year = ENV['ref_plan_active_year']
      action_on_enrollments = ENV['action_on_enrollments']
      plan_year_state = ENV['plan_year_state']

      if organizations.size !=1
        raise 'Issues with fein'
      end

      plan_year = organizations.first.employer_profile.plan_years.where(aasm_state: state).first
      plan_year.revert_renewal! if plan_year.may_revert_renewal? && plan_year_state == "revert_renewal"
      plan_year.revert_application! if plan_year.may_revert_application? && plan_year_state == "revert_application"

      if !(organizations.first.employer_profile.is_conversion?) || organizations.first.employer_profile.renewing_published_plan_year.present?
        return "Renewing plan year for the conversion employer is published (Or) Employer is not a conversion Employer. You cannot perform this action."
      end
      open_enrollment_start_on = (start_on - 30.days).beginning_of_month
      plan_year.update_attributes(start_on: start_on, end_on: start_on + 1.year - 1.day, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_start_on + 13.days)
      puts "Changing Plan Year effective on to #{start_on}" unless Rails.env.test?
      if hios_id.present? && ref_plan_active_year.present?
        plan_year.benefit_groups.each do |benefit_group|
          benefit_group.reference_plan = Plan.where(:hios_id => hios_id, active_year: ref_plan_active_year).first
          benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
          puts "Changed reference plan id " unless Rails.env.test?
        end
      end
      if plan_year.save!
        Rake::Task["migrations:correct_invalid_benefit_group_assignments_for_employer"].invoke unless Rails.env.test?
        puts "Plan Year Saved!!" unless Rails.env.test?
        plan_year.force_publish! if plan_year.may_force_publish? && plan_year_state == "force_publish"
      else
        puts "#{plan_year.errors.full_messages}" unless Rails.env.test?
      end

      bg_list = plan_year.benefit_groups.pluck(:id)
      families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => bg_list)
      enrollments = families.inject([]) do |enrollments, family|
                      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => bg_list)
                    end

      def invalid_enrollment?(enrollment, plan_year)
        enrollment.effective_on < plan_year.start_on
      end

      enrollments.each do |enrollment|
        begin
          if invalid_enrollment?(enrollment, plan_year)
            enrollment.update_attributes!(effective_on: plan_year.start_on)
            puts "updated enrollment effective_on date for HbxEnrollment: #{enrollment.hbx_id}" unless Rails.env.test?
          end
        rescue => e
          puts "Enrollment: #{enrollment.hbx_id} Exception: #{e}"
        end
      end

      if action_on_enrollments == "py_start_on" # when the ask was to change all the enrollments effective on to py start on

        def invalid_enrollment?(enrollment, plan_year)
          enrollment.effective_on != plan_year.start_on
        end

        enrollments.each do |enrollment|
          begin
            if invalid_enrollment?(enrollment, plan_year)
              enrollment.update_attributes!(effective_on: plan_year.start_on)
              puts "updated enrollment effective_on date for HbxEnrollment: #{enrollment.hbx_id}" unless Rails.env.test?
            end
          rescue => e
            puts "Enrollment: #{enrollment.hbx_id} Exception: #{e}"
          end
        end
      end

    rescue Exception => e
      puts e.message
    end
  end
end
