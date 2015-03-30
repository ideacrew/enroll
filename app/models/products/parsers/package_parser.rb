require Rails.root.join('app', 'models', 'products', 'parsers', 'plan_list_parser')

module Parser
  class PackageParser
    include HappyMapper

    #register_namespace "xmlns", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "impl", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "targetNamespace", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

    tag 'packages'

    has_one :plans_list, Parser::PlanListParser, tag: "plansList"

    #has_many :benefits, Parser::BenifitsParser, xpath: 'benefitsList/benefits'

    def to_hash
      {
          plans_list: plans_list.to_hash
      }
    end
  end
end
