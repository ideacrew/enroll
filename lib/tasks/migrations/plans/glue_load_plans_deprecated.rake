#! This rake is deprecated. Please use the rake `bundle exec rake seed:load_products`

namespace :seed do
  task :load_plans, [:year] => :environment do |task, args|

    def build_premium_tables(premium_tables)
      results = premium_tables
      premium_tables.select{|pm| pm[:age] == 14 }.each do |pt|
        (0..13).each do |age_number|
          results << {age: age_number, rate_start_date: pt[:rate_start_date], rate_end_date: pt[:rate_end_date], amount: pt[:amount]}
        end
      end
      premium_tables.select{|pm| pm[:age] == 64 }.each do |pt|
        (65..120).each do |age_number|
          results << {age: age_number, rate_start_date: pt[:rate_start_date], rate_end_date: pt[:rate_end_date], amount: pt[:amount]}
        end
      end
      results
    end
    def dump_plan_for_enroll(plan)
      plan_json = {
        :id => plan.id.to_s,
        :name => plan.name,
        :hios_plan_id => plan.hios_id,
        :hios_base_id => plan.hios_base_id,
        :csr_variant_id => plan.csr_variant_id,
        :ehb => plan.ehb.nil? ? "0.0" : plan.ehb.to_s,
        :year => plan.active_year,
        :carrier_id => plan.carrier_profile_id.to_s,
        :fein => plan.carrier_profile.fein,
        :metal_level => plan.metal_level,
        :coverage_type => plan.coverage_kind,
        :renewal_plan_id => plan.renewal_plan_id,
        :renewal_plan_hios_id => plan.try(:renewal_plan).try(:hios_id),
        :minimum_age => 0,
        :maximum_age => 120,
        :market_type => plan.market
      }
      premium_tables = []
      # t =  build_premium_tables(plan.premium_tables)
      plan.premium_tables.each do |pt|
        if (pt.age < 65) && (pt.age > 13)
          premium_tables << {
            :age => pt.age,
            :rate_start_date => pt.start_on,
            :rate_end_date => pt.end_on,
            :amount => pt.cost
          }
        end
      end
      puts JSON.dump(plan_json.merge({:premium_tables => build_premium_tables(premium_tables).uniq}))
    end
    puts "["
    Plan.where(active_year: args[:year]).each do |pln|
      dump_plan_for_enroll(pln)
      puts(",")
    end
    puts "]"
  end
end