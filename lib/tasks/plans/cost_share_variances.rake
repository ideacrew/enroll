namespace :serff do
  desc "Update cost share variances for assisted"
  task :update_cost_share_variances, [:year] => :environment do |task, args|

    puts "*"*80
    puts "updating cost_share_variances"
    year = args[:year]

    plans = if year.present?
      Plan.individual_market.by_active_year(year)
    else
      Plan.individual_market
    end

    plans.each do |plan|
      qhp = Products::Qhp.where(active_year: plan.active_year, standard_component_id: plan.hios_base_id).first
      if qhp.present?
        hios_id = plan.coverage_kind == "dental" ? (plan.hios_id + "-01") : plan.hios_id
        if hios_id.split("-").last != "01"
          csr = qhp.qhp_cost_share_variances.where(hios_plan_and_variant_id: hios_id).to_a.first
          plan.deductible = csr.qhp_deductable.in_network_tier_1_individual
          plan.family_deductible = csr.qhp_deductable.in_network_tier_1_family
          if plan.valid?
            plan.save
            puts "successfully updated cost_share_variance for #{plan.active_year} plan with hios_id: #{hios_id} "
          end
        end
      end
    end
    puts "*"*80
  end
end