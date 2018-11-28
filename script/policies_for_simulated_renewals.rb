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

feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state => 'renewing_enrolling'}}).pluck(:fein)

clean_feins = feins.map do |f|
  f.gsub(/\D/,"")
end


  enroll_pol_ids = [



  ]

puts enroll_pol_ids.count
# # old_is = File.read("hbx_ids.txt").split("\n").map(&:strip)
# enroll_pol_ids = enroll_pol_ids 
# clean_pol_ids = enroll_pol_ids

# puts clean_pol_ids.count

plan_cache = {}
Plan.all.each do |plan|
  plan_cache[plan.id] = plan
end

def matching_plan_details(enrollment, hen, plan_cache)
  return false if hen.plan_id.blank?
  new_plan = plan_cache[enrollment.plan_id]
  old_plan = plan_cache[hen.plan_id]
  (old_plan.carrier_profile_id == new_plan.carrier_profile_id) && (old_plan.active_year == new_plan.active_year - 1)
end

dependent_add_same_carrier = []
dependent_drop_same_carrier = []
dependent_swap_same_carrier = []

initial_file = File.open("policies_to_pull_ies.txt","w")
renewal_file = File.open("policies_to_pull_renewals.txt","w")

clean_pol_ids.each do |p_id|
  enrollment = HbxEnrollment.by_hbx_id(p_id).first
  renewal_enrollments = enrollment.family.households.flat_map(&:hbx_enrollments).select do |hen|
    hen.is_shop? && (hen.employee_role_id == enrollment.employee_role_id) &&
    hen.terminated_on.blank? && matching_plan_details(enrollment, hen, plan_cache) &&
    (!%w(coverage_terminated unverified void shopping coverage_canceled inactive).include?(hen.aasm_state))
  end

  if renewal_enrollments.any?
    renewal_file.puts(p_id)
  else
    initial_file.puts(p_id)
  end
end