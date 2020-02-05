require File.join(Rails.root, "lib/mongoid_migration_task")

class ReinstateBenefitSponsorship < MongoidMigrationTask
  def migrate
    benefit_sponsorship_id = ENV['id']
    bs = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(benefit_sponsorship_id)
    if bs.aasm_state == :terminated
      bs.reinstate!
      puts "Benefit Sponsorship #{benefit_sponsorship_id} reinstated"
    else
      puts "Cannot reinstate: Benefit Sponsorship #{benefit_sponsorship_id} is not currently terminated"
    end
  end
end
