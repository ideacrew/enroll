module BenefitSponsors
  module Forms
    class Product

      include ActiveModel::Validations
      include Virtus.model

      attribute :title, String
      attribute :issuer_name, String
      attribute :plan_kind, String

    end
  end
end
