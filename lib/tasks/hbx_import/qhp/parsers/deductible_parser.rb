module Parser
  class DeductibleParser
    include HappyMapper

    tag 'planDeductible'

    element :deductible_type, String, tag: "deductibleType"
    element :in_network_tier1_individual, String, tag: "inNetworkTier1Individual"
    element :in_network_tier1_family, String, tag: "inNetworkTier1Family"
    element :coinsurance_in_network_tier_1, String, tag: "coinsuranceInNetworkTier1"
    element :in_network_tier_two_individual, String, tag: "inNetworkTierTwoIndividual"
    element :in_network_tier_two_family, String, tag: "inNetworkTierTwoFamily"
    element :coinsurance_in_network_tier_2, String, tag: "coinsuranceInNetworkTier2"
    element :out_of_network_individual, String, tag: "outOfNetworkIndividual"
    element :out_of_network_family, String, tag: "outOfNetworkFamily"
    element :coinsurance_outof_network, String, tag: "coinsuranceOutofNetwork"
    element :combined_in_or_out_network_individual, String, tag: "combinedInOrOutNetworkIndividual"
    element :combined_in_or_out_network_family, String, tag: "combinedInOrOutNetworkFamily"
    element :combined_in_or_out_tier_2, String, tag: "combinedInOrOutTier2"

    def to_hash
      {
        deductible_type: deductible_type.gsub(/\n/,'').strip,
        in_network_tier1_individual: in_network_tier1_individual.gsub(/\n/,'').strip,
        in_network_tier1_family: in_network_tier1_family.gsub(/\n/,'').strip,
        coinsurance_in_network_tier_1: coinsurance_in_network_tier_1.gsub(/\n/,'').strip,
        in_network_tier_two_individual: in_network_tier_two_individual.gsub(/\n/,'').strip,
        in_network_tier_two_family: in_network_tier_two_family.gsub(/\n/,'').strip,
        coinsurance_in_network_tier_2: coinsurance_in_network_tier_2.gsub(/\n/,'').strip,
        out_of_network_individual: out_of_network_individual.gsub(/\n/,'').strip,
        out_of_network_family: out_of_network_family.gsub(/\n/,'').strip,
        coinsurance_outof_network: coinsurance_outof_network.gsub(/\n/,'').strip,
        combined_in_or_out_network_individual: combined_in_or_out_network_individual.gsub(/\n/,'').strip,
        combined_in_or_out_network_family: combined_in_or_out_network_family.gsub(/\n/,'').strip,
        combined_in_or_out_tier_2: combined_in_or_out_tier_2.gsub(/\n/,'').strip,
      }
    end
  end
end