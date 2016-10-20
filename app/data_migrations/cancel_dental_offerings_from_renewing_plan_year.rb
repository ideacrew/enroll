
require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelDentalOfferingsFromRenewingPlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    bg_id = ENV['benefit_group_id']
    if organizations.size != 1
      puts 'issues with given fein'
      return
    end
    organizations.first.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first.hbx_enrollments.each do |enrollment|
      enrollment.update_attributes(aasm_state: "coverage_canceled") if enrollment.coverage_kind == "dental"
    end
    organizations.first.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first.benefit_groups.where(_id: bg_id).first.unset(:dental_reference_plan_id)
  end
end
