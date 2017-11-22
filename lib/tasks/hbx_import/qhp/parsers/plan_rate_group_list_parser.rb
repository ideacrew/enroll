require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')

module Parser
  class PlanRateGroupListParser
    include HappyMapper

    tag 'qhpApplicationRateGroupListVO'

    has_many :plan_rate_group_attributes, Parser::PlanRateGroupParser, tag: "qhpApplicationRateGroupVO"

    def to_hash
      {
        plan_rate_group_attributes: plan_rate_group_attributes.map(&:to_hash)
      }
    end

  end
end