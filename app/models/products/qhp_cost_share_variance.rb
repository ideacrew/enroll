class Products::QhpCostShareVariance
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  # Component plus variant
  field :hios_plan_and_variant_id, type: String
  field :plan_marketing_name, type: String
  field :metal_level, type: String
  field :csr_variation_type, type: String

  field :issuer_actuarial_value, type: Float
  field :av_calculator_output_number, type: Float

  field :medical_and_drug_deductables_integrated, type: Boolean
  field :medical_and_drug_max_out_of_pocket_integrated, type: Boolean
  field :multiple_provider_tiers, type: Boolean
  field :first_tier_utilization, type: Float
  field :second_tier_utilization, type: Float

  # "having a baby" "having diabetes"
  field :sbc, type: String
  field :moop_list, type: String
  field :plan_deductable_list, type: String
  field :service_visit_list, type: String
  field :default_copay_in_network, type: Money
  field :default_copay_out_of_network, type: Money
  field :default_co_insurance_in_network, type: Money
  field :default_co_insurance_out_of_network, type: Money


### pick up from here

  embeds_one :qhp_summary_benefit_coverage,
    class_name: "Products::QhpSummaryBenefitCoverage",
    cascade_callbacks: true,
    validate: true


# benefit_name: "Maximum Out of Pocket for Medical EHB Benefits"
# benefit_name: "Maximum Out of Pocket for Drug EHB Benefits"
# benefit_name: "Maximum Out of Pocket for Medical and Drug EHB Benefits (Total)"
# benefit_name: "Medical EHB Deductible"
# benefit_name: "Drug EHB Deductible"
# benefit_name: "Combined Medical and Drug EHB Deductible"
# benefit_name: "Subgroup - Pediatric Dental"
# benefit_name: "Primary Care Visit to Treat an Injury or Illness"
# benefit_name: "Specialist Visit"
# benefit_name: "Outpatient Facility Fee (e.g.,  Ambulatory Surgery Center)"
# benefit_name: "Outpatient Surgery Physician/Surgical Services"
# benefit_name: "Hospice Services"
# benefit_name: "Non-Emergency Care When Traveling Outside the U.S."
# benefit_name: "Routine Dental Services (Adult)"
# benefit_name: "Long-Term/Custodial Nursing Home Care"
# benefit_name: "Routine Eye Exam (Adult)"
# benefit_name: "Urgent Care Centers or Facilities"
# benefit_name: "Home Health Care Services"
# benefit_name: "Emergency Room Services"
# benefit_name: "Emergency Transportation/Ambulance"
# benefit_name: "Inpatient Hospital Services (e.g., Hospital Stay)"
# benefit_name: "Inpatient Physician and Surgical Services"
# benefit_name: "Skilled Nursing Facility"
# benefit_name: "Prenatal and Postnatal Care"
# benefit_name: "Delivery and All Inpatient Services for Maternity Care"
# benefit_name: "Mental/Behavioral Health Outpatient Services"
# benefit_name: "Mental/Behavioral Health Inpatient Services"
# benefit_name: "Substance Abuse Disorder Outpatient Services"
# benefit_name: "Substance Abuse Disorder Inpatient Services"
# benefit_name: "Generic Drugs"
# benefit_name: "Preferred Brand Drugs"
# benefit_name: "Non-Preferred Brand Drugs"
# benefit_name: "Specialty Drugs"
# benefit_name: "Outpatient Rehabilitation Services"
# benefit_name: "Habilitation Services"
# benefit_name: "Chiropractic Care"
# benefit_name: "Durable Medical Equipment"
# benefit_name: "Imaging (CT/PET Scans, MRIs)"
# benefit_name: "Preventive Care/Screening/Immunization"
# benefit_name: "Weight Loss Programs"
# benefit_name: "Routine Eye Exam for Children"
# benefit_name: "Eye Glasses for Children"
# benefit_name: "Dental Check-Up for Children"
# benefit_name: "Rehabilitative Speech Therapy"
# benefit_name: "Rehabilitative Occupational and Rehabilitative Physical Therapy"
# benefit_name: "Well Baby Visits and Care"
# benefit_name: "Laboratory Outpatient and Professional Services"
# benefit_name: "X-rays and Diagnostic Imaging"
# benefit_name: "Basic Dental Care - Child"
# benefit_name: "Orthodontia - Child"
# benefit_name: "Major Dental Care - Child"
# benefit_name: "Abortion for Which Public Funding is Prohibited"
# benefit_name: "Transplant"
# benefit_name: "Accidental Dental"
# benefit_name: "Dialysis"
# benefit_name: "Allergy Testing"
# benefit_name: "Chemotherapy"
# benefit_name: "Radiation"
# benefit_name: "Diabetes Education"
# benefit_name: "Prosthetic Devices"
# benefit_name: "Infusion Therapy"
# benefit_name: "Treatment for Temporomandibular Joint Disorders"
# benefit_name: "Nutritional Counseling"
# benefit_name: "Reconstructive Surgery"
# benefit_name: "Clinical Trials"
# benefit_name: "Diabetes Care Management"
# benefit_name: "Prescription Drugs Other"       

end
