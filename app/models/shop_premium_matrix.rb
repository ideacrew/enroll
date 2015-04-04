class ShopPremiumMatrix
  attr_accessor :hbx_enrollment_member_id, 
    :relationship,
    :age_on_effective_date,
    :employer_max_contribution,
    :select_plan_id,
    :plan_premium_total,
    :employee_responsible_amount

  def initialize(premium_matrix) 
    cache_single(premium_matrix)
  end

  def fetch_cost(member_id, plan_ids, key)
    #key: 'single', 'family-detail', 'family-total'
    #TODO exception of not found
    plan_ids.inject({}) do |plan_id, rs|
      cache_key = [key, member_id, plan_id].join('-')
      costs = $redis.get(cache_key)
      rs[plan_id.to_sym] = JSON.parse(costs) if costs
      rs
    end
  end

  def fetch_family_cost(member_id, plan_ids)
    #find a group of summary plan cost for whole family
    plan_ids.inject({}) do |plan_id, rs|
      family_sum_key = ['sum-family', member_id, plan_id].join('-')
      costs = $redis.get(family_sum_key)
      rs[plan_id.to_sym] = JSON.parse(costs) if costs
      rs
    end
  end

  def fetch_family_detail_cost(member_id, plan_ids)
    plan_ids.inject({}) do |plan_id, rs|
      family_detail_key = ['family-detail', member_id, plan_id].join('-')
      costs = $redis.get(family_detail_key)
      rs[plan_id.to_sym] = JSON.parse(costs) if costs
      rs
    end
  end

  def cache_single(premium_matrix)
    single_key = ['single', 
                  premium_matrix[:hbx_enrollment_member_id], 
                  premium_matrix[:select_plan_id]].join('-')

    $reids.set(single_key, {
      relationship: premium_matrix[:relationship],
      age_on_effective_date: premium_matrix[:age_on_effective_date],
      employer_max_contribution: premium_matrix[:employer_max_contribution],
      select_plan_id: premium_matrix[:select_plan_id],
      plan_premium_total: premium_matrix[:plan_premium_total],
      employee_responsible_amount: premium_matrix[:employee_responsible_amount]
    }.to_json)
  end

  def cache_sum_family(premium_matrix_list, member_id, plan_id)
    family_sum_key = ['sum-family', member_id, plan_id].join('-')
    family_sum_cost = premium_matrix_list.inject({}) do |premium_matrix, rs| 
      rs[:sum_plan_premium_total] += premium_matrix[:plan_premium_total]
      rs[:sum_employer_max_contribution] += premium_matrix[:employer_max_contribution]
      rs[:sum_employee_responsible_amount] += premium_matrix[:employee_responsible_amount]
      rs
    end

    $reids.set(family_sum_key, family_sum_cost.to_json)
  end

  def cache_family_detail(premium_matrix_list, member_id, plan_id)
    family_detail_key = ['family-detail', member_id, plan_id].join('-')
    family_detail_cost = premium_matrix_list.map do |premium|
      single_key = ['single', member_id, plan_id].join('-')
      $redis.get(single_key)
    end

    $redis.set(family_detail_key, family_detail_cost.to_json)
  end

end
