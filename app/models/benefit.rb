class Benefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan

  field :primary_care_visit_cost, type: String
  field :urgent_care_visit_cost, type: String
  field :specialist_visit_cost, type: String
  field :emergency_room_service_cost, type: String
  field :hospitalization_cost, type: String
  field :laboratory_service_cost, type: String
  field :diagnostic_service_cost, type: String  # x-ray or imaging
  field :generic_drug_cost, type: String
  field :preferred_brand_name_drug_cost, type: String
  field :non_preferred_brand_name_drug_cost, type: String
  field :speciality_drug_cost, type: String

end