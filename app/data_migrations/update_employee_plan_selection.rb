require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEmployeePlanSelection < MongoidMigrationTask
  def migrate
    begin
      organization=Organization.where(fein: ENV['fein'].to_s).first
      plan_id=Plan.where(hios_id:ENV['hios_id'], active_year: ENV['active_year']).first.id
      if organization.nil? || plan_id.nil?
        puts "No organization or plan was found by the given information"
      else
        benefit_groups= organization.try(:employer_profile).try(:active_plan_year).try(:benefit_groups)
        if benefit_groups.nil?
          puts "No benefit groups found with given information"
        else
          bg_list=benefit_groups.map{|a| a.id}
          Family.where(:"households.hbx_enrollments.benefit_group_id".in => bg_list).each do |family|
            family.active_household.hbx_enrollments.where(:benefit_group_id.in => bg_list, :plan_id.ne => nil).to_a.each do |enrollment|
              enrollment.update_attributes(plan_id: plan_id)
              puts "Changed Plan of Enrollment for #{family.primary_family_member.person.hbx_id}"
            end
          end
        end
      end
    rescue
      puts e.errors
    end
  end
end