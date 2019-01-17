require Rails.root.join('lib', 'tasks', 'hbx_import','plan_cross_walk_parser')

module Parser
  class PlanCrossWalkListParser
    include HappyMapper

    tag 'crosswalks'

    has_many :crosswalks, Parser::PlanCrossWalkParser, tag: "crosswalk"

    def to_hash
      {
        crosswalks: crosswalks.map(&:to_hash)
      }
    end
  end
end