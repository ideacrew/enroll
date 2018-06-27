# Renew everybody who needs to be renewed

start_on_date = Date.today.next_month.beginning_of_month

def find_renewed_sponsorships(start_date)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        "predecessor_id" => {"$ne" => nil},
        "aasm_state" => {"$in" => [
          :enrollment_open,
          :enrollment_closed,
          :enrollment_eligible,
          :active
        ]}
      }
    }
  })
end

def find_renewable_benefit_applications(start_date, already_renewed_ids)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        "predecessor_id" => {"$ne" => nil},
        "aasm_state" => {"$in" => [
          :draft,
          :approved
        ]}
      }
    },
    "_id" => {"$nin" => already_renewed_ids}
  })
end

benefit_applications = []
benefit_sponsorships.each{|bs| benefit_applications << select_benefit_application(bs)}

force_renewal_eligible = find_renewable_benefit_applications(
  start_on_date,
  find_renewed_sponsorships(start_on_date).pluck("_id")
)

force_renewal_eligible.each do |bs|
  selected_application = bs.benefit_applications.detect do |ba|
    (!ba.predecessor_id.blank?) &&
      (ba.start_on == start_on_date)
  end
  begin
    selected_application.simulate_provisional_renewal! if selected_application.may_simulate_provisional_renewal?
  rescue Exception => e
    puts "Could not force publish #{selected_application.benefit_sponsorship.organization.legal_name} because of #{e.inspect}"
    next
  end
end