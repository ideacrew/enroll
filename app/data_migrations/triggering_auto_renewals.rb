
require File.join(Rails.root, "lib/mongoid_migration_task")

class TriggeringAutoRenewals < MongoidMigrationTask
  def migrate
    plan_year_start_on = Date.strptime(ENV['py_start_on'], "%m/%d/%Y")
    count = 0
    Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => plan_year_start_on, :aasm_state => 'renewing_enrolling'}}, :'employer_profile.profile_source' => 'conversion' ).each do |org|
      org.employer_profile.census_employees.each do |ce|
        enrollments = ce.try(:employee_role).try(:person).try(:primary_family).try(:active_household).try(:hbx_enrollments)
        if enrollments.present? && enrollments.where(aasm_state: "renewing_waived").present?
          count = count+1
          enrollments.where(aasm_state: "renewing_waived").each do |enr|
            enr.delete
          end
        end
      end
       org.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first.trigger_passive_renewals
    end
    puts "The total effected ER's count is #{Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => plan_year_start_on, :aasm_state => 'renewing_enrolling'}}, :'employer_profile.profile_source' => 'conversion' ).count}" 
    puts "The total effected EE's count is #{count}"
  end
end
