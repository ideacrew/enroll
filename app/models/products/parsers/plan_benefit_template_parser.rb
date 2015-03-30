require Rails.root.join('app', 'models', 'products', 'parsers', 'package_list_parser')

module Parser
  class PlanBenefitTemplateParser
    include HappyMapper

    #register_namespace "xmlns", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "impl", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "targetNamespace", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

    tag 'planBenefitTemplateVO'

    has_one :packages_list, Parser::PackageListParser, :tag => "packagesList"

    #has_many :benefits, Parser::BenifitsParser, xpath: 'benefitsList/benefits'

    def to_hash
      {
          packages_list: packages_list.to_hash
      }
    end
  end
end
