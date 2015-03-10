class PlansParser
  include HappyMapper
  tag 'benefits'
  element :benefit_type_code, String, :tag => 'benefitTypeCode'
end

