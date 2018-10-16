qs = Queries::PolicyAggregationPipeline.new
  start_on_date = Date.today.end_of_month + 1.day + 1.month
  feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state => 'renewing_enrolling'}}).pluck(:fein)
  clean_feins = feins.map do |f|
    f.gsub(/\D/,"")
  end
  qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => (start_on_date - 1.day)}).eliminate_family_duplicates
  enroll_pol_ids = []
  excluded_ids = []
  qs.evaluate.each do |r|
    enroll_pol_ids << r['hbx_id']
  end
  glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)
  
  enroll_pol_ids = enroll_pol_ids - (glue_list + excluded_ids)
  clean_pol_ids = enroll_pol_ids
  
  dependent_add_same_carrier = []
  dependent_drop_same_carrier = []
  dependent_swap_same_carrier = []
  
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
  
  clean_pol_ids.each do |p_id|
    enrollment = HbxEnrollment.by_hbx_id(p_id).first
    renewal_enrollments = enrollment.family.households.flat_map(&:hbx_enrollments).select do |hen|
      hen.is_shop? && (hen.employee_role_id == enrollment.employee_role_id) &&
      hen.terminated_on.blank? && matching_plan_details(enrollment, hen, plan_cache) &&
      (!%w(coverage_terminated unverified void shopping coverage_canceled inactive).include?(hen.aasm_state))
    end
    
    if !renewal_enrollments.any?
      puts enrollment.hbx_id
    end
  end
