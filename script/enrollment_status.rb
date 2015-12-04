def shop_policies_count
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "$or" => [
        {"households.hbx_enrollments.consumer_role_id" => {"$exists" => false}},
        {"households.hbx_enrollments.consumer_role_id" => nil}
      ],
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]}
    }
  })
  q.add({
    "$group" => {"_id" => "1", "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.first["count"]
end

def individual_policies_count
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]}
    }
  })
  q.add({
    "$group" => {"_id" => "1", "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.first["count"]
end

def individual_policies_2016
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => Date.new(2016,1,1),
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]},
    }
  })
  q.add({
    "$group" => {"_id" => "1", "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.first["count"]
end

def individual_policies_2016_by_purchase_date
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => Date.new(2016,1,1),
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]},
    }
  })
  q.add({
    "$project" => {
      "policy_created_on" => {"$dateToString" => {"format" => "%Y-%m-%d", "date" => "$households.hbx_enrollments.created_at"}},
      "policy_submitted_on" => {"$dateToString" => {"format" => "%Y-%m-%d", "date" => "$households.hbx_enrollments.submitted_at"}}
    }
  })
  q.add({
    "$group" => {"_id" => {"created_on" => "$policy_created_on", "submitted_on" => "$policy_submitted_on"}, "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.map do |r|
    [[r["_id"]["created_on"], r["_id"]["submitted_on"]].compact.first, r["count"]]
  end.sort_by { |v| v.first }
end

puts "2016 IVLs by purchase date:"
individual_policies_2016_by_purchase_date.each do |v|
  puts "#{v.first} : #{v.last}"
end

# puts "Shop policies: #{shop_policies_count}"
# puts "Individual policies: #{individual_policies_count}"
# puts "Individual policies, 2016: #{individual_policies_2016}"
