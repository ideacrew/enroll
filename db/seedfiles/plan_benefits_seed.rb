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

# puts "::: Generating Sample Plans:::"
# 
# plan1 = Plan.new(name: "KP DC Platinum 0/10/Dental/Ped Dental", coverage_kind: "dental", metal_level: "platinum", market: "individual", carrier_profile_id: "1234", active_year: "2015", hios_id: "00009876-02")
# benefit1 = Benefit.new(in_diagnostic_service_cost: "$5",
#                       in_emergency_room_service_cost: "$250",
#                       in_generic_drug_cost: "$10",
#                       in_hospitalization_cost: "$250 Copay per Day",
#                       in_laboratory_service_cost: "$5",
#                       in_non_preferred_brand_name_drug_cost: "$50",
#                       in_preferred_brand_name_drug_cost: "$30",
#                       in_primary_care_visit_cost: "$10",
#                       in_specialist_visit_cost: "$20",
#                       in_speciality_drug_cost: "$30",
#                       in_urgent_care_visit_cost: "$20",
#                       :out_generic_drug_cost=> "$0",
#                       :out_diagnostic_service_cost => "$0",
#                       :out_emergency_room_service_cost => "$250",
#                       :out_hospitalization_cost => "$250 Copay per Day",
#                       :out_laboratory_service_cost => "$0",
#                       :out_non_preferred_brand_name_drug_cost => "$0",
#                       :out_preferred_brand_name_drug_cost => "$0",
#                       :out_primary_care_visit_cost => "100%",
#                       :out_specialist_visit_cost => "100%",
#                       :out_speciality_drug_cost => "$0",
#                       :out_urgent_care_visit_cost => "100%")
# 
# plan1.benefits << benefit1
# plan1.save!
# 
# 
# plan2 = Plan.new(name: "BlueChoice HSA Bronze $4,000", coverage_kind: "health", metal_level: "bronze", market: "individual", carrier_profile_id: "1232", active_year: "2015", hios_id: "00009871-02")
# benefit2 = Benefit.new(in_diagnostic_service_cost: "$0 Copay after deductible",
#                       in_emergency_room_service_cost: "$0 Copay after deductible",
#                       in_generic_drug_cost: "$10",
#                       in_hospitalization_cost: "$0 Copay per Stay",
#                       in_laboratory_service_cost: "$0 Copay after deductible",
#                       in_non_preferred_brand_name_drug_cost: "$0 Copay after deductible",
#                       in_preferred_brand_name_drug_cost: "$0 Copay after deductible",
#                       in_primary_care_visit_cost: "$30 Copay after deductible",
#                       in_specialist_visit_cost: "$40 Copay after deductible",
#                       in_speciality_drug_cost: "$0 Copay after deductible",
#                       in_urgent_care_visit_cost: "$0 Copay after deductible",
#                       :out_generic_drug_cost=> "$0 Copay after deductible",
#                       :out_diagnostic_service_cost => "$0",
#                       :out_emergency_room_service_cost => "$0 Copay after deductible",
#                       :out_hospitalization_cost => "$0 Copay per Stay",
#                       :out_laboratory_service_cost => "$0",
#                       :out_non_preferred_brand_name_drug_cost => "$0 Copay after deductible",
#                       :out_preferred_brand_name_drug_cost => "$0 Copay after deductible",
#                       :out_primary_care_visit_cost => "$0",
#                       :out_specialist_visit_cost => "$0",
#                       :out_speciality_drug_cost => "$0 Copay after deductible",
#                       :out_urgent_care_visit_cost => "$0")
# 
# plan2.benefits << benefit2
# plan2.save!
# 
# 
# plan3 = Plan.new(name: "Aetna Bronze $20 Copay", coverage_kind: "health", metal_level: "bronze", market: "individual", carrier_profile_id: "1231", active_year: "2015", hios_id: "00009176-02")
# benefit3 = Benefit.new(in_diagnostic_service_cost: "$100 Copay after deductible",
#                       in_emergency_room_service_cost: "$250 Copay after deductible",
#                       in_generic_drug_cost: "$15",
#                       in_hospitalization_cost: "$250 Copay per Stay",
#                       in_laboratory_service_cost: "No Charge",
#                       in_non_preferred_brand_name_drug_cost: "$75",
#                       in_preferred_brand_name_drug_cost: "$45",
#                       in_primary_care_visit_cost: "$20",
#                       in_specialist_visit_cost: "$50 Copay after deductible",
#                       in_speciality_drug_cost: "$0",
#                       in_urgent_care_visit_cost: "$60 Copay after deductible",
# 
#                       :out_generic_drug_cost=> "$0",
#                       :out_diagnostic_service_cost => "No Charge",
#                       :out_emergency_room_service_cost => "$250 Copay after deductible",
#                       :out_hospitalization_cost => "$0 Copay per Dy",
#                       :out_laboratory_service_cost => "No Charge",
#                       :out_non_preferred_brand_name_drug_cost => "$0",
#                       :out_preferred_brand_name_drug_cost => "$0",
#                       :out_primary_care_visit_cost => "No Charge",
#                       :out_specialist_visit_cost => "No Charge",
#                       :out_speciality_drug_cost => "$0",
#                       :out_urgent_care_visit_cost => "No Charge")
# 
# plan3.benefits << benefit3
# plan3.save!
# 



puts "::: End Generating Sample Plans:::"
puts "*"*80