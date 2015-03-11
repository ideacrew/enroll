puts "*"*80
puts "::: Generating Sample Plans:::"

plan1 = Plan.new(name: "KP DC Platinum 0/10/Dental/Ped Dental", coverage_kind: "dental", metal_level: "platinum", market: "individual", carrier_profile_id: "1234", active_year: "2015", hios_id: "00009876-02")
benefit1 = Benefit.new(in_diagnostic_service_cost: "$5",
                      in_emergency_room_service_cost: "$250",
                      in_generic_drug_cost: "$10",
                      in_hospitalization_cost: "$250 Copay per Day",
                      in_laboratory_service_cost: "$5",
                      in_non_preferred_brand_name_drug_cost: "$50",
                      in_preferred_brand_name_drug_cost: "$30",
                      in_primary_care_visit_cost: "$10",
                      in_specialist_visit_cost: "$20",
                      in_speciality_drug_cost: "$30",
                      in_urgent_care_visit_cost: "$20",
                      :out_generic_drug_cost=> "$0",
                      :out_diagnostic_service_cost => "$0",
                      :out_emergency_room_service_cost => "$250",
                      :out_hospitalization_cost => "$250 Copay per Day",
                      :out_laboratory_service_cost => "$0",
                      :out_non_preferred_brand_name_drug_cost => "$0",
                      :out_preferred_brand_name_drug_cost => "$0",
                      :out_primary_care_visit_cost => "100%",
                      :out_specialist_visit_cost => "100%",
                      :out_speciality_drug_cost => "$0",
                      :out_urgent_care_visit_cost => "100%")

plan1.benefits << benefit1
plan1.save!


plan2 = Plan.new(name: "BlueChoice HSA Bronze $4,000", coverage_kind: "health", metal_level: "bronze", market: "individual", carrier_profile_id: "1232", active_year: "2015", hios_id: "00009871-02")
benefit2 = Benefit.new(in_diagnostic_service_cost: "$0 Copay after deductible",
                      in_emergency_room_service_cost: "$0 Copay after deductible",
                      in_generic_drug_cost: "$10",
                      in_hospitalization_cost: "$0 Copay per Stay",
                      in_laboratory_service_cost: "$0 Copay after deductible",
                      in_non_preferred_brand_name_drug_cost: "$0 Copay after deductible",
                      in_preferred_brand_name_drug_cost: "$0 Copay after deductible",
                      in_primary_care_visit_cost: "$30 Copay after deductible",
                      in_specialist_visit_cost: "$40 Copay after deductible",
                      in_speciality_drug_cost: "$0 Copay after deductible",
                      in_urgent_care_visit_cost: "$0 Copay after deductible",
                      :out_generic_drug_cost=> "$0 Copay after deductible",
                      :out_diagnostic_service_cost => "$0",
                      :out_emergency_room_service_cost => "$0 Copay after deductible",
                      :out_hospitalization_cost => "$0 Copay per Stay",
                      :out_laboratory_service_cost => "$0",
                      :out_non_preferred_brand_name_drug_cost => "$0 Copay after deductible",
                      :out_preferred_brand_name_drug_cost => "$0 Copay after deductible",
                      :out_primary_care_visit_cost => "$0",
                      :out_specialist_visit_cost => "$0",
                      :out_speciality_drug_cost => "$0 Copay after deductible",
                      :out_urgent_care_visit_cost => "$0")

plan2.benefits << benefit2
plan2.save!


plan3 = Plan.new(name: "Aetna Bronze $20 Copay", coverage_kind: "health", metal_level: "bronze", market: "individual", carrier_profile_id: "1231", active_year: "2015", hios_id: "00009176-02")
benefit3 = Benefit.new(in_diagnostic_service_cost: "$100 Copay after deductible",
                      in_emergency_room_service_cost: "$250 Copay after deductible",
                      in_generic_drug_cost: "$15",
                      in_hospitalization_cost: "$250 Copay per Stay",
                      in_laboratory_service_cost: "No Charge",
                      in_non_preferred_brand_name_drug_cost: "$75",
                      in_preferred_brand_name_drug_cost: "$45",
                      in_primary_care_visit_cost: "$20",
                      in_specialist_visit_cost: "$50 Copay after deductible",
                      in_speciality_drug_cost: "$0",
                      in_urgent_care_visit_cost: "$60 Copay after deductible",

                      :out_generic_drug_cost=> "$0",
                      :out_diagnostic_service_cost => "No Charge",
                      :out_emergency_room_service_cost => "$250 Copay after deductible",
                      :out_hospitalization_cost => "$0 Copay per Dy",
                      :out_laboratory_service_cost => "No Charge",
                      :out_non_preferred_brand_name_drug_cost => "$0",
                      :out_preferred_brand_name_drug_cost => "$0",
                      :out_primary_care_visit_cost => "No Charge",
                      :out_specialist_visit_cost => "No Charge",
                      :out_speciality_drug_cost => "$0",
                      :out_urgent_care_visit_cost => "No Charge")

plan3.benefits << benefit3
plan3.save!




puts "::: End Generating Sample Plans:::"
puts "*"*80
