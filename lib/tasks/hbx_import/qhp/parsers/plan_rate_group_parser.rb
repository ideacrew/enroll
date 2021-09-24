require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_header_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_items_parser')

module Parser
  class PlanRateGroupParser
    include HappyMapper

    tag 'qhpApplicationRateGroupVO'

    has_one :header, Parser::PlanRateHeaderParser, tag: "header"
    has_many :items, Parser::PlanRateItemsParser, tag: "items"
    element :rating_method, String, tag: 'ratingMethod'

    def to_hash
      {
        rating_method: rating_method.present? ? rating_method.gsub(/\n/,'').strip : "",
        header: header.to_hash,
        items: items.map(&:to_hash)
      }
    end
  end
end
