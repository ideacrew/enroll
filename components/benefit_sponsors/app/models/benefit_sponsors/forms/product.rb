module BenefitSponsors
  module Forms
    class Product

      include ActiveModel::Validations
      include Virtus.model

      attribute :title, String
      attribute :issuer_name, String
      attribute :plan_kind, String
      attribute :metal_level_kind, String
      attribute :network_information, String
      attribute :network, String
      attribute :is_standard_plan, Boolean
      attribute :is_hc4cc_plan, Boolean
    end
  end
end
