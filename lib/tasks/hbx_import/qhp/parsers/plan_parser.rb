require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_attributes_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'cost_share_variances_list_parser')

module Parser
  class PlanParser
    include HappyMapper

    tag 'plans'

    has_one :plan_attributes, Parser::PlanAttributesParser, tag: 'planAttributes'
    has_one :cost_share_variances_list, Parser::CostShareVariancesListParser, tag: "costShareVariancesList"

    def to_hash
      {
          plan_attributes: plan_attributes.to_hash,
          cost_share_variances_list: cost_share_variances_list.to_hash
      }
    end
  end
end
