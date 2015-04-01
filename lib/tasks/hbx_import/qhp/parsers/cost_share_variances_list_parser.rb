require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','cost_share_variance_parser')

module Parser
  class CostShareVariancesListParser
    include HappyMapper

    tag "costShareVariancesList"

    has_one :cost_share_variance, Parser::CostShareVarianceParser, tag: "costShareVariance"

    def to_hash
      {
          cost_share_variance: cost_share_variance.to_hash
      }
    end
  end
end