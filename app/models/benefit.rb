class Benefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan

  field :in_primary_care_visit_cost, type: String
  field :in_urgent_care_visit_cost, type: String
  field :in_specialist_visit_cost, type: String
  field :in_emergency_room_service_cost, type: String
  field :in_hospitalization_cost, type: String
  field :in_laboratory_service_cost, type: String
  field :in_diagnostic_service_cost, type: String  # x-ray or imaging
  field :in_generic_drug_cost, type: String
  field :in_preferred_brand_name_drug_cost, type: String
  field :in_non_preferred_brand_name_drug_cost, type: String
  field :in_speciality_drug_cost, type: String
  field :out_primary_care_visit_cost, type: String
  field :out_urgent_care_visit_cost, type: String
  field :out_specialist_visit_cost, type: String
  field :out_emergency_room_service_cost, type: String
  field :out_hospitalization_cost, type: String
  field :out_laboratory_service_cost, type: String
  field :out_diagnostic_service_cost, type: String  # x-ray or imaging
  field :out_generic_drug_cost, type: String
  field :out_preferred_brand_name_drug_cost, type: String
  field :out_non_preferred_brand_name_drug_cost, type: String
  field :out_speciality_drug_cost, type: String

  PLAN_BENEFITS = [
    "Primary Care Visit to Treat an Injury or Illness",
    "Urgent Care Centers or Facilities",
    "Specialist Visit",
    "Emergency Room Services",
    "Inpatient Hospital Services (e.g., Hospital Stay)",
    "Laboratory Outpatient and Professional Services",
    "X-rays and Diagnostic Imaging",
    "Generic Drugs",
    "Preferred Brand Drugs",
    "Non-Preferred Brand Drugs",
    "Specialty Drugs"
  ]

end