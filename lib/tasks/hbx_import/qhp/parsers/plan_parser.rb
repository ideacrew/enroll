require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_attributes_parser')

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
