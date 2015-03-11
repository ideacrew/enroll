class PlansParser
  include HappyMapper
  tag 'serviceVisit'
  element :visit_type, String, :tag => 'visitType'
  element :copay_in_network_tier1, String, :tag => 'copayInNetworkTier1'
  element :copay_out_of_network, String, :tag => 'copayOutOfNetwork'
  element :co_insurance_in_network_tier1, String, :tag => 'coInsuranceInNetworkTier1'
  element :co_insurance_out_of_network, String, :tag => 'coInsuranceOutOfNetwork'
end

