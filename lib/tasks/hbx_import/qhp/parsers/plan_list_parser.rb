require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_parser')

module Parser
  class PlanListParser
    include HappyMapper

    #register_namespace "xmlns", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "impl", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "targetNamespace", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

    tag 'plansList'

    has_many :plans, Parser::PlanParser, tag: "plans"

    def to_hash
      {
        plans: plans.map(&:to_hash)
      }
    end
  end
end
