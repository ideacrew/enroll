qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_active_terminated_expired.with_effective_date({"$gt" => Date.new(2015,12,31)}).eliminate_family_duplicates

all_enroll_policies = File.new("all_enroll_policies.txt","w")

qs.evaluate.each do |r|
    all_enroll_policies.puts(r['hbx_id'])
end