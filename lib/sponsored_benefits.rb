require "sponsored_benefits/engine"

require "mongoid"
require "aasm"
require 'config'

module SponsoredBenefits
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :settings
  end
end
