def shop_policies_count
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_shop
  q.add({
    "$group" => {"_id" => "1", "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.first["count"]
end

def individual_policies_count
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_individual
  q.add({
    "$group" => {"_id" => "1", "count" => {"$sum" => 1}}
  })
  results = q.evaluate
  results.first["count"]
end

def individual_policies_2016
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_individual
  q.add({
    "$match" => {
      "households.hbx_enrollments.effective_on" => Date.new(2016,1,1)
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
  q.filter_to_shop
  q.group_by_purchase_date
end

def individual_sep_policies_by_purchase_date
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_individual
  q.with_effective_date(
      {"$ne" => Date.new(2016,1,1)}
  )
  q.group_by_purchase_date
end

def individual_policies_by_purchase_date
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_individual
  q.group_by_purchase_date
end

def individual_sep_policies_by_purchase_date_after(date)
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_individual
  q.with_effective_date({"$lt" => Date.new(2016,1,1)})
  q.group_by_purchase_date do |query|
    query.add({
      "$match" => {
        "policy_purchased_at" => {"$gte" => date}
      }
    })
  end
end

def shop_oe_policies_by_purchase_date_after(date)
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_shop
  q.with_effective_date({"$gt" => Date.new(2015,12,31)})
  q.group_by_purchase_date do |query|
    query.add({
      "$match" => {
        "policy_purchased_at" => {"$gte" => date}
      }
    })
  end
end

def shop_sep_policies_by_purchase_date_after(date)
  q = Queries::PolicyAggregationPipeline.new
  q.filter_to_shop
  q.with_effective_date({"$lt" => Date.new(2016,1,1)})
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
  q.filter_to_individual
  q.with_effective_date({"$gt" => Date.new(2015,12,31)})
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

puts "IVL OE by purchase date after #{date}:"
individual_oe_policies_by_purchase_date_after(date).each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end

puts "Shop SEP (coverage date before 2016-01-01) by purchase date after #{date}:"
shop_sep_policies_by_purchase_date_after(date).each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end

puts "Shop (coverage date == 2016-01-01, including SEPs) by purchase date after #{date}:"
shop_oe_policies_by_purchase_date_after(date).each do |v|
  unless v.first == "2015-10-13"
    puts "#{v.first} : #{v.last}"
  end
end
