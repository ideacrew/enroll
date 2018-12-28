require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitSponosorshipStates < MongoidMigrationTask

  def migrate
    old_states = [:initial_application_under_review, :initial_application_denied, :initial_application_approved, :initial_enrollment_open, :initial_enrollment_closed, :initial_enrollment_ineligible, :initial_enrollment_eligible]
    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"aasm_state".in => old_states)
    benefit_sponsorships.each do |benefit_sponsorship|
      begin
        if benefit_sponsorship.aasm_state == :initial_enrollment_eligible
          benefit_application = benefit_sponsorship.benefit_applications.enrollment_eligible.first
          benefit_application.update_attributes!(aasm_state: :binder_paid) if benefit_application
          puts "Updating #{benefit_sponsorship.organization.legal_name}'s benefit application state to :binder_paid state" unless Rails.env.test?
        end
        benefit_sponsorship.update_attributes!(aasm_state: :applicant)
        puts "Updating #{benefit_sponsorship.organization.legal_name}'s benefit sponsorship state to :applicant" unless Rails.env.test?
      rescue Exception => e
        puts "Error occured for #{benefit_sponsorship.organization.legal_name} due to #{e.inspect}" unless Rails.env.test?
      end
    end
  end
end