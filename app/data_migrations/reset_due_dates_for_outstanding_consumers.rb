require File.join(Rails.root, "lib/mongoid_migration_task")

class ResetDueDatesForOutstandingConsumers < MongoidMigrationTask
  def migrate
    family = Family.by_enrollment_individual_market.where(:"households.hbx_enrollments"=>{"$elemMatch"=>
      {:aasm_state => "coverage_selected", :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year,
        :"$lte" =>  TimeKeeper.date_of_record.end_of_year }}}).each do |family|
      begin
        family.active_household.hbx_enrollments.individual_market.where(aasm_state: "coverage_selected").each do |hbx_enrollment|
          if hbx_enrollment.is_any_member_outstanding? && hbx_enrollment.may_move_to_contingent?
            family.set_due_date_on_verification_types
            hbx_enrollment.move_to_contingent!
            puts "enrollment with #{hbx_enrollment.hbx_id} associated to #{person.hbx_id} moved to contingent" unless Rails.env.test?
          end
        end
      rescue Exception => e
        puts "Exception in family ID #{person.hbx_id}: #{e}" unless Rails.env.test?
      end
    end
  end
end
