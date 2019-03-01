module Notifier
  class MergeDataModels::RelationshipBenefit
    include Virtus.model

    attribute :relationship, String
    attribute :premium_pct, Integer

    def self.stubbed_object
      Notifier::MergeDataModels::RelationshipBenefit.new({
        relationship: 'employee',
        premium_pct: 80
        })
    end
  end
end
