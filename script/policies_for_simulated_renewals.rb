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

renewed_sponsorships = find_renewed_sponsorships

CSV.open("simulated_renewals.csv", 'w') do |csv|

csv << ["policy_id", "FEIN"]
renewed_sponsorships.each do |bs|
  fein = bs.profile.organization.fein
  selected_application = bs.benefit_applications.detect do |ba|
    (!ba.predecessor_id.blank?) &&
      (ba.start_on == start_on_date) &&
      [:enrollment_open,
        :enrollment_closed,
        :enrollment_eligible,
        :active].include?(ba.aasm_state)
  end

  employer_enrollment_query = ::Queries::NamedEnrolmentQueries.find_simulated_renewal_enrollments(selected_application.sponsored_benefits, start_on_date)
  employer_enrollment_query.each do |enrollment_hbx_id|
    csv << [enrollment_hbx_id, fein]
  end
end
end