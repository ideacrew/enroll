require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdatePyAnnouncedExternallyFlag < MongoidMigrationTask

  def migrate

    organizations = Organization.where(:"employer_profile.plan_years" =>
                           { :$elemMatch => {
                               :"aasm_state".in => PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE
                           }
                           })

    organizations.each do |org|
      org.employer_profile.plan_years.published_or_renewing_published.each do |py|
        if py.active? || ((py.enrolled? && py.binder_paid?) || py.renewing_enrolled?) && py.past_transmission_threshold? && py.open_enrollment_completed?
        py.update_attributes(announced_externally: true)
        end
      end
    end
  end
end
