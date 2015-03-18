class PlansParser
  include HappyMapper
  tag 'planAttributes'
  element :name, String, :tag => "planMarketingName"
  element :metal_level, String, :tag => "metalLevel"
  element :active_year, Date, :tag => "planEffectiveDate"
  element :standard_component_id, String, :tag => "standardComponentID"
end