module BenefitMarkets
  class Configuration
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :configurable, polymorphic: true
  end
end
