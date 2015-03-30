class Products::QhpDeductable
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp_cost_share_variance

  # Plan deductable list
  field :deductable_type, type: String   
  field :in_network_tier_1_individual, type: Money
  field :in_network_tier_1_family, type: Money
  field :coinsurance_in_network_tier_1, type: Money

  field :in_network_tier_2_individual, type: Money
  field :in_network_tier_2_family, type: Money
  field :coinsurance_in_network_tier_2, type: Money

  field :out_of_network_individual, type: Money
  field :out_of_network_family, type: Money
  field :coinsurance_out_of_network, type: Money

  field :combined_in_out_network_individual, type: Money
  field :combined_in_out_network_family, type: Money
  field :combined_in_out_network_tier_2, type: Money

end
