require File.join(Rails.root, "lib/mongoid_migration_task")

class ResetDueDatesForOutstandingConsumers < MongoidMigrationTask
  def migrate
    Person.all_consumer_roles.where(:"consumer_role.aasm_state" => "verification_outstanding").each do |person|
      begin
        family = person.primary_family
        next unless family
        family.active_household.hbx_enrollments.individual_market.enrolled.each do |hbx_enrollment|
          if hbx_enrollment.is_any_member_outstanding? && hbx_enrollment.may_move_to_contingent?
            family.set_due_date_on_verification_types
            hbx_enrollment.move_to_contingent!
            puts "" unless Rails.env.test?
          end
        end
      rescue Exception => e
        puts "Exception in family ID #{person.hbx_id}: #{e}" unless Rails.env.test?
      end
    end
  end
end

