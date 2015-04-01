require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','deductible_parser')

module Parser
  class DeductibleListParser
    include HappyMapper

    tag 'planDeductibleList'

    has_one :deductible, Parser::DeductibleParser, tag: "planDeductible"

    def to_hash
      {
          deductible: deductible.to_hash
      }
    end
  end
end
