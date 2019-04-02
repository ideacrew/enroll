module Notifier
  class MergeDataModels::RelationshipBenefit
    include Virtus.model

    attribute :relationship, String
    attribute :premium_pct, Integer

    def self.stubbed_object
      rel_hash = {
        'Employee' => 80,
        'Spouse' => 80,
        'Domestic Partner' => 80,
        'Child Under 26' => 80
      }
      rel_hash.collect do |k, v|
        Notifier::MergeDataModels::RelationshipBenefit.new(
          {
            relationship: k,
            premium_pct: v
          }
        )
      end
    end
  end
end
