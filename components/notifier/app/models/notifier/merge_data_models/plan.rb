module Notifier
  class MergeDataModels::Plan
    include Virtus.model

    attribute :coverage_start_on, Date
    attribute :coverage_end_on, Date
    attribute :plan_name, String
    attribute :metal_level, String
    attribute :coverage_kind, String
    attribute :plan_carrier, String
    attribute :hsa_plan, Boolean
    attribute :renewal_plan_type, String
  end
end
