require Rails.root.join('app', 'models', 'products', 'parsers', 'package_parser')

module Parser
  class PackageListParser
    include HappyMapper

    #register_namespace "xmlns", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "impl", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "targetNamespace", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

    tag 'packagesList'

    has_many :packages, Parser::PackageParser, tag: "packages"

    #has_many :benefits, Parser::BenifitsParser, xpath: 'benefitsList/benefits'

    def to_hash
      {
          packages: packages.map(&:to_hash)
      }
    end
  end
end
