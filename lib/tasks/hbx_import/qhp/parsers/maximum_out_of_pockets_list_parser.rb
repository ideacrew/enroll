require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','maximum_out_of_pockets_parser')

module Parser
  class MaximumOutOfPocketsListParser
    include HappyMapper

    tag 'moopList'

    has_many :maximum_out_of_pockets, Parser::MaximumOutOfPocketsParser, tag: "moop"

    def to_hash
      {
          maximum_out_of_pockets: maximum_out_of_pockets.map(&:to_hash)
      }
    end
  end
end
