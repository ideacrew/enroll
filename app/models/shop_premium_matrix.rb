class ShopPremiumMatrix
  #:hbx_enrollment_member_id, 
  #:relationship,
  #:age_on_effective_date,
  #:employer_max_contribution,
  #:select_plan_id,
  #:plan_premium_total,
  #:employee_responsible_amount
  def initialize(premium_matrix) 
    @@premium_table ||= Array.new
    @@premium_table << premium_matrix
  end


  class << self
    def fetch_cost(member_id, plan_ids, key)
      #key: 'single', 'family-detail', 'family-total'
      plan_ids.inject({}) do |rs, plan_id|
        cache_key = [key, member_id, plan_id].join('-')
        costs = $redis.get(cache_key)
        rs[plan_id] = JSON.parse(costs) if costs
        rs
      end
    end

    def cache_sum_family(member_id, plan_id)
      family_sum_key = ['family-total', member_id, plan_id].join('-')
      family_sum_cost = @@premium_table.select do |premium|
        premium[:hbx_enrollment_member_id] == member_id && premium[:select_plan_id] == plan_id
      end.compact.inject({}) do |rs, premium_matrix| 
        rs[:sum_plan_premium_total] = add_or_equal(rs[:sum_plan_premium_total], premium_matrix[:plan_premium_total])
        rs[:sum_employer_max_contribution] = add_or_equal(rs[:sum_employer_max_contribution], premium_matrix[:employer_max_contribution])
        rs[:sum_employee_responsible_amount] = add_or_equal(rs[:sum_employee_responsible_amount], premium_matrix[:employee_responsible_amount])
        rs
      end

      $redis.set(family_sum_key, family_sum_cost.to_json)
    end

    def cache_family_detail(member_id, plan_id)
      family_detail_key = ['family-detail', member_id, plan_id].join('-')
      family_detail_cost = @@premium_table.select do |premium|
        premium[:hbx_enrollment_member_id] == member_id && premium[:select_plan_id] == plan_id
      end.compact

      $redis.set(family_detail_key, family_detail_cost.to_json)
    end

    def cache_single(premium_matrix)
      #please only cache to single while relationship is :employee
      #do not cache signle dependent, they are not unique
      single_key = ['single', 
                    premium_matrix[:hbx_enrollment_member_id], 
                    premium_matrix[:select_plan_id]].join('-')

      $redis.set(single_key, {
        relationship: premium_matrix[:relationship],
        age_on_effective_date: premium_matrix[:age_on_effective_date],
        employer_max_contribution: premium_matrix[:employer_max_contribution],
        select_plan_id: premium_matrix[:select_plan_id],
        plan_premium_total: premium_matrix[:plan_premium_total],
        employee_responsible_amount: premium_matrix[:employee_responsible_amount]
      }.to_json)
    end

    private
    def add_or_equal(rs_hash, new_value)
      rs_hash.nil?? new_value : rs_hash + new_value
    end

  end
end
