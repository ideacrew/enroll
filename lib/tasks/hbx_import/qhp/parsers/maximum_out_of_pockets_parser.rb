module Parser
  class MaximumOutOfPocketsParser
    include HappyMapper

    tag 'moop'

    element :name, String, tag: "name"
    element :in_network_tier_1_individual_amount, String, tag: "inNetworkTier1IndividualAmount"
    element :in_network_tier_1_family_amount, String, tag: "inNetworkTier1FamilyAmount"
    element :in_network_tier_2_individual_amount, String, tag: "inNetworkTier2IndividualAmount"
    element :in_network_tier_2_family_amount, String, tag: "inNetworkTier2FamilyAmount"
    element :out_of_network_individual_amount, String, tag: "outOfNetworkIndividualAmount"
    element :out_of_network_family_amount, String, tag: "outOfNetworkFamilyAmount"
    element :combined_in_out_network_individual_amount, String, tag: "combinedInOutNetworkIndividualAmount"
    element :combined_in_out_network_family_amount, String, tag: "combinedInOutNetworkFamilyAmount"

    def to_hash
      {
        name: name.gsub(/\n/,'').strip,
        in_network_tier_1_individual_amount: in_network_tier_1_individual_amount.gsub(/\n/,'').strip,
        in_network_tier_1_family_amount: in_network_tier_1_family_amount.gsub(/\n/,'').strip,
        in_network_tier_2_individual_amount:  in_network_tier_2_individual_amount.present? ? in_network_tier_2_individual_amount.gsub(/\n/,'').strip : "",
        in_network_tier_2_family_amount: in_network_tier_2_family_amount.present? ? in_network_tier_2_family_amount.gsub(/\n/,'').strip : "",
        out_of_network_individual_amount: out_of_network_individual_amount.gsub(/\n/,'').strip,
        out_of_network_family_amount: out_of_network_family_amount.gsub(/\n/,'').strip,
        combined_in_out_network_individual_amount: combined_in_out_network_individual_amount.gsub(/\n/,'').strip,
        combined_in_out_network_family_amount: combined_in_out_network_family_amount.gsub(/\n/,'').strip,
      }
    end
  end
end