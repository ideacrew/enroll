require 'securerandom'

class HbxIdGenerator
  include Singleton

  def self.generate_policy_id
    random_uuid
  end

  def self.generate_member_id
    random_uuid
  end

  def self.generate_organization_id
    random_uuid
  end

  def self.random_uuid
    timestamp = Time.now.strftime("%m%d%H%M%S%L")
    random_number = SecureRandom.random_number(100 / 2)
    "#{timestamp}#{random_number}".to_i
  end
end
