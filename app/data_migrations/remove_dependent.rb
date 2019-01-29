require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDependent < MongoidMigrationTask
  def migrate
    begin
      ids = ENV["family_member_id"].to_s.split(",")

      family_members = []
      ids.each do |id|
        fm = FamilyMember.find(id)
        if fm.present?
          family_members.push(fm)
        else
          puts "No family member found with id: '#{id}'"
        end
      end

      family_members.each do |fm|
        active_household = fm.family.active_household
        coverage_household = active_household.coverage_households.where(:is_immediate_family => true).first
        enrollments = active_household.hbx_enrollments.my_enrolled_plans.where(:"aasm_state".ne => "coverage_canceled")

        if (coverage_household.coverage_household_members.map(&:family_member_id).map(&:to_s) & [fm.id]).present?|| (enrollments.map(&:hbx_enrollment_members).flatten.uniq.map(&:applicant_id).map(&:to_s) & [fm.id]).present?
          puts "You cannot remove family member '#{fm.id}'. This member may have Coverage Household Member records or Enrollments." unless Rails.env.test?
          return
        else
          fm.destroy!
          puts "Removed dependent with family member id: '#{fm.id}'" unless Rails.env.test?
        end
      end
    rescue Exception => e
      puts e.message
    end
  end
end
