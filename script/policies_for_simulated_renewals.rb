date = Date.today

if date.day > 15
  window_start = Date.new(date.year,date.month,16)
  window_end = Date.new(date.next_month.year,date.next_month.month,15)
  window = (window_start..window_end)
elsif date.day <= 15
  window_start = Date.new((date - 1.month).year,(date - 1.month).month,16)
  window_end = Date.new(date.year,date.month,15)
  window = (window_start..window_end)
end

start_on_date = window.end.next_month.beginning_of_month.to_time.utc.beginning_of_day

plan_cache = {}

Plan.all.each do |plan|
  plan_cache[plan.id] = plan
end

def find_renewed_sponsorships(start_date)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        # "predecessor_id" => {"$ne" => nil},
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

def matching_plan_details(enrollment, other_hbx_enrollment, plan_cache)
  return false if other_hbx_enrollment.plan_id.blank?
  new_plan = plan_cache[enrollment.plan_id]
  old_plan = plan_cache[other_hbx_enrollment.plan_id]
  (old_plan.carrier_profile_id == new_plan.carrier_profile_id) &&
    (old_plan.active_year == new_plan.active_year - 1)
end

def initial_or_renewal(enrollment,plan_cache)
  renewal_enrollments = enrollment.family.households.flat_map(&:hbx_enrollments).select do |hbx_enrollment|
    hbx_enrollment.is_shop? &&
      (hbx_enrollment.employee_role_id == enrollment.employee_role_id) &&
      hbx_enrollment.terminated_on.blank? &&
      matching_plan_details(enrollment, hbx_enrollment, plan_cache) &&
      (!%w(coverage_terminated unverified void shopping coverage_canceled inactive).include?(hbx_enrollment.aasm_state))
  end
  if renewal_enrollments.any?
    return "renewal"
  else
    return "initial"
  end
end

renewed_sponsorships = find_renewed_sponsorships(start_on_date)

f = File.open("policies_to_pull.txt","w")

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

  initial_enrollments = []

  renewal_enrollments = []

  employer_enrollment_query = ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(selected_application.sponsored_benefits, start_on_date)
  employer_enrollment_query.each do |enrollment_hbx_id|
    enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
    if initial_or_renewal(enrollment,plan_cache) == 'initial'
      initial_enrollments << enrollment_hbx_id
    elsif initial_or_renewal(enrollment,plan_cache) == 'renewal'
      renewal_enrollments << enrollment_hbx_id
    f.puts(enrollment_hbx_id)
  end
end