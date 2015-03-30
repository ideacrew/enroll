require Rails.root.join('app', 'models', 'products', 'parsers', 'plan_attributes_parser')

module Parser
  class PlanParser
    include HappyMapper

    tag 'plans'

    has_one :planAttributes, Parser::PlanAttributesParser, tag: 'planAttributes'

    def to_hash
      {
          planAttributes: planAttributes.to_hash
      }
    end
  end
end
