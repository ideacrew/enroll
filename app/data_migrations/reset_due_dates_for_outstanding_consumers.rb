require File.join(Rails.root, "lib/mongoid_migration_task")

class ResetDueDatesForOutstandingConsumers < MongoidMigrationTask
  def migrate
    family = Family.by_enrollment_individual_market.where(:"households.hbx_enrollments"=>{"$elemMatch"=>
      {:aasm_state => "coverage_selected", :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year,
        :"$lte" =>  TimeKeeper.date_of_record.end_of_year }}}).each do |family|
      begin
        family.active_household.hbx_enrollments.individual_market.where(aasm_state: "coverage_selected").each do |hbx_enrollment|
          if hbx_enrollment.is_any_member_outstanding?
            family.set_due_date_on_verification_types
            puts "Due dates have been set for family associated with id: #{family.id} " unless Rails.env.test?
          end
        end
      rescue Exception => e
        puts "Exception in family ID #{family.id}: #{e}" unless Rails.env.test?
      end
    end
  end
end
