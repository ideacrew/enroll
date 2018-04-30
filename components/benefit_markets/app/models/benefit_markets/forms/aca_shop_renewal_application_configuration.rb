module BenefitMarkets
  module Forms
    class AcaShopRenewalApplicationConfiguration
      extend  ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations
      include Virtus.model

      attribute :mm_enr_due_on, Integer
      attribute :vr_os_window, Integer
      attribute :vr_due, Integer
      attribute :open_enrl_start_on, Date
      attribute :open_enrl_end_on, Date

    end
  end
end