module Config::AcaModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :individual_market_is_enabled?, to: :class
  end

  class_methods do
    def individual_market_is_enabled?
      @@individual_market_is_enabled ||= Settings.aca.market_kinds.include? "individual"
    end
  end
end
