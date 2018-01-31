require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','benefits_parser')

module Parser
  class BenefitsListParser
    include HappyMapper

    #register_namespace "xmlns", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "impl", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "targetNamespace", "http://vo.ffe.cms.hhs.gov"
    #register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

    tag 'benefitsList'

    has_many :benefits, Parser::BenefitsParser, tag: "benefits"

    def to_hash
      {
        benefits: benefits.map(&:to_hash)
      }
    end
  end
end
