module BenefitMarkets
	module Configurations
	  class Configuration
	    include Mongoid::Document
	    include Mongoid::Timestamps

	    embedded_in :benefit_market

      field :key,     type: String
      field :value,   type: String

      scope :get_all,  -> (starting_with) {
        where(key: /^#{::Regexp.escape(starting_with)}/i)
      }

      scope :by_key, -> (key) { 
        where(key: key)
      }

      index({ key: 1 }, { unique: true })

      validates_uniqueness_of :key

      def write_cache
        Rails.cache.write(cache_key, value)
      end

      def expire_cache
        Rails.cache.delete(cache_key)
      end

      def cache_key
        self.class.cache_key(key, benefit_market)
      end

      class << self

        def cache_key(key, scope_object)
          scope = ["configurations"]
          scope << "#{scope_object.class.name}-#{scope_object.id}" if scope_object
          scope << key.to_s
          scope.join("-")
        end

        def [](market_kind, key)
          benefit_market = benefit_market_for(market_kind)
          val = Rails.cache.fetch(cache_key(key, benefit_market)) do
            setting = find_setting(benefit_market, key)
            setting.value
          end
          val
        end

        # set a setting value by [] notation
        def []=(market_kind, key, value)
          benefit_market = benefit_market_for(market_kind)
          key = key.to_s
          setting = find_setting(benefit_market, key) || benefit_market.configurations.new(key: key)
          setting.value = value
          setting.save!
          setting.write_cache
          value
        end

        def find_setting(benefit_market, key)
          benefit_market.configurations.by_key(key).first
        end

        def benefit_market_for(market_kind)
          BenefitMarkets::BenefitMarket.by_kind(market_kind.to_sym)
        end
      end
	  end
	end
end