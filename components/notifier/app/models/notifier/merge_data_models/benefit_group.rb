module Notifier
  class MergeDataModels::BenefitGroup
    include Virtus.model

    attribute :start_on, String
    attribute :title, String
    attribute :plan_option_kind, String
    attribute :reference_plan_name, String
    attribute :reference_plan_carrier_name, String
    attribute :plan_offerings_text, String
    attribute :relationship_benefits, Array[MergeDataModels::RelationshipBenefit]

    def self.stubbed_object
      benefit_group = Notifier::MergeDataModels::BenefitGroup.new({
        start_on: "12/1/2018",
        title: "Adams Benefit Group",
        plan_option_kind: 'single_plan',
        reference_plan_name: 'Blue Cross Blue Shieldd HMO',
        reference_plan_carrier_name: 'BCBS'
        })
      benefit_group.relationship_benefits = Notifier::MergeDataModels::RelationshipBenefit.stubbed_object
      benefit_group
    end
  end
end
