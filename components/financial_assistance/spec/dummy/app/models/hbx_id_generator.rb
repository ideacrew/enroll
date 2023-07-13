# frozen_string_literal: true

class HbxIdGenerator
  attr_accessor :provider
  include Singleton

  def initialize
    @provider = AmqpSource
  end

  def generate_member_id
    provider.generate_member_id
  end

  def generate_policy_id
    provider.generate_policy_id
  end

  def generate_payment_transaction_id
    provider.generate_payment_transaction_id
  end

  def generate_organization_id
    provider.generate_organization_id
  end

  def generate_application_id
    provider.generate_application_id
  end

  def self.slug!
    self.instance.provider = SlugSource
  end

  def self.generate_policy_id
    self.instance.generate_policy_id
  end

  def self.generate_payment_transaction_id
    self.instance.generate_payment_transaction_id
  end

  def self.generate_member_id
    self.instance.generate_member_id
  end

  def self.generate_organization_id
    self.instance.generate_organization_id
  end

  def self.generate_application_id
    self.instance.generate_application_id
  end

  class AmqpSource
    def self.generate_id_from_sequence(sequence_name)
      request_result = nil
      retry_attempt = 0
      while (retry_attempt < 3) && request_result.nil?
        request_result = Acapi::Requestor.request("sequence.next", {:sequence_name => sequence_name}, 2)
        retry_attempt += 1
      end
      JSON.load(request_result.stringify_keys["body"]).first.to_s
    end

    def self.generate_member_id
      generate_id_from_sequence("member_id")
    end

    def self.generate_policy_id
      generate_id_from_sequence("policy_id")
    end

    def self.generate_payment_transaction_id
      generate_id_from_sequence("payment_transaction_id")
    end

    def self.generate_organization_id
      generate_id_from_sequence("organization_id")
    end

    def self.generate_application_id
      generate_id_from_sequence("faa_application_id")
    end
  end

  class SlugSource
    def self.generate_organization_id
      uniq_id
    end

    def self.generate_policy_id
      uniq_id
    end

    def self.generate_payment_transaction_id
      uniq_id
    end

    def self.generate_member_id
      uniq_id
    end

    def self.uniq_id
      Time.now.to_i
    end

    def self.generate_application_id
      uniq_id
    end
  end
end

# Fix slug setting on request reload
HbxIdGenerator.slug! unless Rails.env.production?

