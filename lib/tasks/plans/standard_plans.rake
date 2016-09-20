namespace :xml do
  task :standard_plans, [:file] => :environment do |task,args|

    standard_hios_ids = ["94506DC0390001-01","94506DC0390005-01","94506DC0390007-01","94506DC0390011-01","86052DC0400001-01","86052DC0400002-01","86052DC0400007-01","86052DC0400008-01","78079DC0210001-01","78079DC0210002-01","78079DC0210003-01","78079DC0210004-01"]
    Plan.by_active_year(2016).where(:hios_id.in => standard_hios_ids).each do |plan|
      plan.update(is_standard_plan: true)
      puts "Plan with hios_id #{plan.hios_id} updated to standard plan."
    end

  end
end