# This script is for the demo environment: it does two things
# It changes all mentions of "Maine" to "State" in the titles of all instances of BenefitMarkets::Products::Product
# It can be run with bundle exec rails r script/sanitize_plan_info.rb

plans = BenefitMarkets::Products::Product.where(title: /maine/i)

plans.each do |plan|
  plan.title = plan.title.gsub(/maine/i, 'State')
  plan.save
end

puts "All plan titles containing \'Maine\' successfully updated"