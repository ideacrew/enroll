require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeRenewingPlanYearAasmState< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        return unless ENV['plan_year_start_on'].present?
        plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
        plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on).first
        if plan_year.present?
          plan_year.revert_renewal! if plan_year.may_revert_renewal?
          plan_year.withdraw_pending! if plan_year.renewing_publish_pending?
          plan_year.renew_publish! if plan_year.may_renew_publish?
          plan_year.advance_date! if plan_year.may_advance_date? # renewing_enrolling
          plan_year.advance_date! if plan_year.is_enrollment_valid? && plan_year.is_open_enrollment_closed? && plan_year.may_advance_date? # to renewing_enrolled
          plan_year.activate! if plan_year.renewing_enrolled? && plan_year.may_activate? # for late renewal employer plan year already started employer moving plan year to active state.
          puts "Plan year aasm state changed to #{plan_year.aasm_state}" unless Rails.env.test?
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
