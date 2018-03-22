module SponsoredBenefits
  class Rosters::Roster
    include Enumerable


    embeds_many :members

    # At each primary member level, include
    #   product_reference




# let(:list_bill_attrs) {
#         {
#           "benefit_application_attributes" => {
#             "start_on"=>"2018-05-01", "end_on"=>"2019-04-30", "open_enrollment_start_on"=>"2018-03-14", "open_enrollment_end_on"=>"2018-04-10", "fte_count"=>"25", "pte_count"=>"10", "msp_count"=>"0",
#             "benefit_groups_attributes" => {
#              "0"=>{"title"=>"New Benefit Group", "description"=>"First Benefit Group", "effective_on_offset"=>"0", 
#                "relationship_benefits_attributes"=>
#                {"0"=>{"relationship"=>"employee", "premium_pct"=>"80"}, 
#                "1"=>{"offered"=>"true", "relationship"=>"spouse", "premium_pct"=>"70"}, 
#                "2"=>{"offered"=>"true", "relationship"=>"domestic_partner", "premium_pct"=>"0"}, 
#                "3"=>{"offered"=>"true", "relationship"=>"child_under_26", "premium_pct"=>"0"}, 
#                "4"=>{"offered"=>"false", "relationship"=>"child_26_and_over", "premium_pct"=>"0"}},
#                "effective_on_kind"=>"first_of_month",
#                "plan_option_kind"=>"single_carrier",
#                "carrier_for_elected_plan"=>"53e67210eb899a460300000d",
#                "reference_plan_id"=>"59f72cf1faca145fb8005c08",
#                "dental_relationship_benefits_attributes"=>{
#                 "0"=>{"offered"=>"true", "relationship"=>"employee", "premium_pct"=>"0"},
#                 "1"=>{"offered"=>"true", "relationship"=>"spouse", "premium_pct"=>"0"},
#                 "2"=>{"offered"=>"true", "relationship"=>"domestic_partner", "premium_pct"=>"0"},
#                 "3"=>{"offered"=>"true", "relationship"=>"child_under_26", "premium_pct"=>"0"},
#                 "4"=>{"offered"=>"false", "relationship"=>"child_26_and_over", "premium_pct"=>"0"}},
#                "carrier_for_elected_dental_plan"=>"", "dental_reference_plan_id"=>"", "dental_relationship_benefits_attributes_time"=>"0"}


  end
end
