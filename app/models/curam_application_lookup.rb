require 'singleton'

class CuramApplicationLookup
  include Singleton

  attr_accessor :provider

  def initialize
    @provider = AmqpSource
  end

  def search_curam_financial_app(person_demographics)
    provider.search_curam_financial_app person_demographics
  end

  def self.slug!
    self.instance.provider = SlugSource
  end

  class AmqpSource
    def self.search_curam_financial_app(person_demographics)
      request_result = nil
      retry_attempt = 0
      while (retry_attempt < 3) && request_result.nil?
        request_result = Acapi::Requestor.request("account_management.check_existing_account", person_demographics, 2)
        retry_attempt = retry_attempt + 1
      end
      request_result.stringify_keys["return_status"]
    end
  end

  class SlugSource
    def self.search_curam_financial_app(person_demographics)
      "NO_CURAM_DATA_FOUND"
    end
  end
end

unless Rails.env.production?
  CuramApplicationLookup.slug!
end