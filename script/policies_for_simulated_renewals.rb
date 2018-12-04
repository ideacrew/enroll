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

  

 feins = ["521867908",	
"521010600",	
"521199774",	
"742466507",	
"455175802",	
"204154254",	
"273716946",	
"822279926",	
"521300905",	
"823355541",	
"272151294",	
"521999196",	
"753191322",	
"581593137",	
"593789738",	
"526055574",	
"453968516",	
"521838761",	
"471029811",	
"273842102",	
"273932996",	
"300580158",	
"215445533",	
"208287695",	
"264778921",	
"454746975",	
"830511031",	
"461411907",	
"010936175",
"273968567",	
"520824700",	
"821743329",	
"412107332",	
"465383496",	
"473737369",	
"260867057",	
"526060093",	
"463300839",	
"300699122",	
"813214432",	
"475337318",	
"520812075",	
"043836074",	
"465515079",	
"132508249",	
"464107791",	
"472214606",	
"473610995",	
"475188263",	
"474146803",	
"262067123",	
"522192717",	
"521902099",	
"521261435",	
"205762966",	
"264108806"]	


feins.each do |fein|
  org = Organization.where(fein:fein).first
  py = org.employer_profile.renewing_plan_year

  # puts"Org is #{org.fein} before is #{py.aasm_state}"
  # org.employer_profile.renewing_plan_year.force_publish! if py.may_force_publish? && py.is_application_valid?
  puts"Org is #{org.fein} after is #{py.aasm_state}"
  
end
# Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state => 'renewing_enrolling'}}).pluck(:fein)

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