require 'securerandom'

class HbxIdGenerator
  attr_accessor :provider
  include Singleton

  def initialize
    @provider = AmqpSource
  end

  def generate
    provider.generate
  end

  def self.slug!
    self.instance.provider = SlugSource
  end

  def self.generate
    self.instance.generate
  end

  class AmqpSource
    def self.generate
      JSON.load(Acapi::Requestor.request("sequence.next", {:sequence_name => "member_id"}).stringify_keys[:body]).first
    end
  end

  class SlugSource
    def self.generate
      SecureRandom.uuid.gsub("-","")
    end
  end
end

# Fix slug setting on request reload
unless Rails.env.production?
  HbxIdGenerator.slug!
end

