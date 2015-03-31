require Rails.root.join('app', 'models', 'products', 'parsers', 'package_parser')

module Parser
  class PackageListParser
    include HappyMapper

    tag 'packagesList'

    has_many :packages, Parser::PackageParser, tag: "packages"

    #has_many :benefits, Parser::BenifitsListParser, xpath: 'benefitsList/benefits'

    def to_hash
      {
          packages: packages.map(&:to_hash)
      }
    end
  end
end
