module Config::SiteModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :site_short_name, :to => :class
    delegate :site_key, :to => :class
    delegate :is_shop_market_enabled?, :to => :class
    delegate :is_fehb_market_enabled?, :to => :class
    delegate :is_shop_or_fehb_market_enabled?, :to => :class
    delegate :is_individual_market_enabled?, :to => :class
    delegate :is_shop_and_individual_market_enabled?, :to => :class
  end

  class_methods do
    def site_short_name
      EnrollRegistry[:enroll_app].setting(:short_name).item
    end

    def site_key
      NotifierRegistry[:enroll_app].settings(:site_key).item
    end

    def is_shop_market_enabled?
      NotifierRegistry.feature_enabled?(:aca_shop_market)
    end

    def is_fehb_market_enabled?
      NotifierRegistry.feature_enabled?(:fehb_market)
    end

    def is_shop_or_fehb_market_enabled?
      NotifierRegistry.feature_enabled?(:fehb_market) || NotifierRegistry.feature_enabled?(:aca_shop_market)
    end

    def is_individual_market_enabled?
      NotifierRegistry.feature_enabled?(:aca_individual_market)
    end

    def is_shop_and_individual_market_enabled?
      NotifierRegistry.feature_enabled?(:aca_shop_market) && NotifierRegistry.feature_enabled?(:aca_individual_market)
    end
  end
end
