puts "*"*80
require 'plans_parser'

#destroy_all command added to delete plans at safe side can comment if want
Plan.destroy_all

puts ":::Generating Plans from xml file:::"

blacklist_plan_names = ["UnitedHealthcare Gold Choice Plus HRA 2000","UnitedHealthcare Platinum Choice Plus HRA 1000","UnitedHealthcare Gold Choice HRA 2000", "UnitedHealthcare Platinum Choice HRA 1000"]
blacklist_hios_ids = ["41842DC0010070","41842DC0010071","41842DC0040048","41842DC0040049"]

provider_dirs = Dir.glob("#{Rails.root}/db/data/xml/planxmls/*")
provider_dirs.each do |directory|
  files = Dir.glob("#{directory}/*")
  provider =  directory
  provider.slice! "#{Rails.root}/db/data/xml/planxmls"
  files.each do |file|
    file_contents = File.read(file)
    PlansParser.parse(file_contents).each do |plan_parse|
      plan_name = plan_parse.name.squish
      hios_id = plan_parse.standard_component_id.squish
      if (!blacklist_plan_names.include? plan_name) && (!blacklist_hios_ids.include? hios_id)
        
        plan = Plan.new(provider: provider, name: plan_name, market: "individual", coverage_kind: "dental", carrier_profile_id: "1234", hios_id: hios_id, metal_level: plan_parse.metal_level.squish, active_year: plan_parse.active_year.strftime("%Y"))
        plan_benefits = []
        plan_parse.instance_variables.each do |variable_name|
          variable_name = variable_name.to_s.gsub!("@","")
          value = plan_parse.send("#{variable_name}").to_s
          if value.present?
            value = value.squish
          end
          plan_benefits << PlanBenefit.new(benefit_attribute_name: variable_name, benefit_attribute_value: value)
        end
        
        plan.plan_benefits = plan_benefits
        plan.save!
      end
    end
  end
  
end  

puts ":::End Generating Plans from xml file:::"

puts "::: End Generating Sample Plans:::"
puts "*"*80