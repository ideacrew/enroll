module Queries
  class PolicyAggregationPipeline
    def initialize
      @pipeline = base_pipeline
    end

    def base_pipeline
      [
        { "$unwind" => "$households"},
        { "$unwind" => "$households.hbx_enrollments"}
      ]
    end

    def add(step)
      @pipeline << step
    end

    def evaluate
      Family.collection.raw_aggregate(@pipeline)
    end

    def group_by_purchase_date
      add({
        "$project" => {
          "policy_created_on" => {"$dateToString" => {"format" => "%Y-%m-%d", "date" => "$households.hbx_enrollments.created_at"}},
          "policy_submitted_on" => {"$dateToString" => {"format" => "%Y-%m-%d", "date" => "$households.hbx_enrollments.submitted_at"}}
        }
      })
      add({
        "$group" => {"_id" => {"created_on" => "$policy_created_on", "submitted_on" => "$policy_submitted_on"}, "count" => {"$sum" => 1}}
      })
      results = self.evaluate
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
  end
end
