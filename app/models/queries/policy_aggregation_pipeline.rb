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

    def denormalize
      add({
        "$project" => {
          "_id" => "$households.hbx_enrollments.hbx_id",
          "policy_purchased_at" => { 
            "$dateToString" => {"format" => "%Y-%m-%d %H:%M:S",
              "date" => {"$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }}},
          "policy_purchased_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
                                "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
          }
          },
          "policy_effective_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
            "date" => "$households.hbx_enrollments.effective_on"}},
          "enrollee_count" => {"$size" => {"$ifNull" => ["$households.hbx_enrollments.hbx_enrollment_members", []]}},
          "market" => {"$cond" => ["$households.hbx_enrollments.consumer_role_id","SHOP","IVL"]},
          "plan_id" => "$households.hbx_enrollments.plan_id"
        }})
      self
    end

    def filter_to_active
      add({
        "$match" => {
          "households.hbx_enrollments.plan_id" => { "$ne" => nil},
          "households.hbx_enrollments.aasm_state" => { "$nin" => [
            "shopping", "inactive", "coverage_canceled", "coverage_terminated"
          ]}
        }
      })
      self
    end

    def filter_to_individual
      add({
        "$match" => {
          "households.hbx_enrollments.plan_id" => { "$ne" => nil},
          "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
          "households.hbx_enrollments.aasm_state" => { "$nin" => [
            "shopping", "inactive", "coverage_canceled", "coverage_terminated"
          ]}
        }
      })
      self
    end

    def with_effective_date(criteria)
      add({
        "$match" => {
          "households.hbx_enrollments.effective_on" => criteria
        }
      })
    end

    def filter_to_shop
      add({
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
      self
    end

    def hbx_id_with_purchase_date_and_time
      add({
        "$project" => {
          "policy_purchased_at" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] },
          "policy_purchased_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
                                "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
          }
          },
          "hbx_id" => "$households.hbx_enrollments.hbx_id"
        }})
      yield self if block_given?
      results = self.evaluate
      results.map do |r|
        r['hbx_id']
      end
    end

    def group_by_purchase_date
      add({
        "$project" => {
          "policy_purchased_at" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] },
          "policy_purchased_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
                                "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
          }
          }
        }})
      yield self if block_given?
      add({
        "$group" => {"_id" => {"purchased_on" => "$policy_purchased_on"}, "count" => {"$sum" => 1}}
      })
      results = self.evaluate
      h = results.inject({}) do |acc,r|
        k = r["_id"]["purchased_on"]
        if acc.has_key?(k)
          acc[k] = acc[k] + r["count"]
        else
          acc[k] = r["count"]
        end
        acc
      end
      result = h.keys.sort.map do |k|
        [k, h[k]]
      end
      total = result.inject(0) do |acc, i|
        acc + i.last
      end
      result << ["Total     ", total] 
    end
  end
end
