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

def shop_policies_by_purchase_date
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
  by_purchase_date(q)
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
      ]}
    }
  })
  by_purchase_date(q)
end

def individual_sep_policies_by_purchase_date
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => {"$ne" => Date.new(2016,1,1) },
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]}
    }
  })
  by_purchase_date(q)
end

def individual_policies_by_purchase_date
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
  by_purchase_date(q)
end

def by_purchase_date(q)
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
  h = results.inject({}) do |acc,r|
    k = [r["_id"]["created_on"], r["_id"]["submitted_on"]].compact.first
    if acc.has_key?(k)
      acc[k] = acc[k] + r["count"]
    else
      acc[k] = r["count"]
    end
    acc
  end
  h.keys.sort.map do |k|
    [k, h[k]]
  end
end

puts "IVL SEP by purchase date:"
individual_sep_policies_by_purchase_date.each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end

# puts "Shop policies: #{shop_policies_count}"
# puts "Individual policies: #{individual_policies_count}"
# puts "Individual policies, 2016: #{individual_policies_2016}"
