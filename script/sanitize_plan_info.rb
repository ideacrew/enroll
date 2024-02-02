plans = BenefitMarkets::Products::Product.where(title: /maine/i)

plans.each do |plan|
  plan.title = plan.title.gsub(/maine/i, 'State')
  plan.save
end

puts "All plan titles containing \'Maine\' successfully updated"