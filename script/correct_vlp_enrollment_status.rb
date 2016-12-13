# Identify all people in the vlp outstanding state

consumer_roles = Person.collection.aggregate([
  {"$match" => {"consumer_role.aasm_state" => "verifications_outstanding"}},
  {"$group" => {"_id" => "$consumer_role._id"}}
])

consumer_role_ids = []

consumer_roles.each do |rec|
  consumer_role_ids << rec["_id"]
end

affected_policies = Family.collection.aggregate([
  {"$unwind" => "$households"},
  {"$unwind" => "$households.hbx_enrollments"},
  {"$match" => { 
    "households.hbx_enrollments.consumer_role_id" => {"$in" => consumer_role_ids},
    "households.hbx_enrollments.plan_id" => {"$ne" => nil},
    "households.hbx_enrollments.aasm_state" => {
      "$nin" => ["inactive", "coverage_canceled", "enrolled_contingent"]
    }
  } },
  { "$match" => {
    "households.hbx_enrollments.effective_on" => {"$gt" => Date.new(2015,12,31)},
    "$or" => [
      {"households.hbx_enrollments.terminated_on" => nil},
      {"households.hbx_enrollments.terminated_on" => {"$gt" => Date.today }}
    ]
  }},
  {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
])

affected_policy_ids = []

affected_policies.each do |rec|
  affected_policy_ids << rec["_id"]
end

affected_policy_ids.each do |p_id|
  policy = HbxEnrollment.by_hbx_id(p_id).first
  policy.evaluate_individual_market_eligiblity
  policy.save!
end
