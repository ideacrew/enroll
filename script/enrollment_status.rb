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
  q.group_by_purchase_date
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
  q.group_by_purchase_date
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
  q.group_by_purchase_date
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
  q.group_by_purchase_date
end

def individual_sep_policies_by_purchase_date_after(date)
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => {"$lt" => Date.new(2016,1,1)},
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]}
    }
  })
  q.group_by_purchase_date do |query|
    query.add({
      "$match" => {
        "policy_purchased_at" => {"$gte" => date}
      }
    })
  end
end

def individual_oe_policies_by_purchase_date_after(date)
  q = Queries::PolicyAggregationPipeline.new
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => {"$gt" => Date.new(2015,12,31)},
      "households.hbx_enrollments.plan_id" => { "$ne" => nil},
      "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
      "households.hbx_enrollments.aasm_state" => { "$nin" => [
        "shopping", "inactive", "coverage_canceled", "coverage_terminated"
      ]}                        
    }                               
  })
  q.group_by_purchase_date do |query|
    query.add({
      "$match" => {
        "policy_purchased_at" => {"$gte" => date}
      }
    })
  end
end

date = DateTime.new(2015,11,29,23,55,00, "-4")
puts "IVL SEP by purchase date after #{date}:"
individual_sep_policies_by_purchase_date_after(date).each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end

date = DateTime.new(2015,11,29,23,55,00, "-4")
puts "IVL OE by purchase date after #{date}:"
individual_oe_policies_by_purchase_date_after(date).each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end

# puts "Shop policies: #{shop_policies_count}"
# puts "Individual policies: #{individual_policies_count}"
# puts "Individual policies, 2016: #{individual_policies_2016}"
