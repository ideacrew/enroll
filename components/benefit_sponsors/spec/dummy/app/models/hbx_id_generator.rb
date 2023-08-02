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

  # Random UUID generator combining a timestamp and random number to generate a unique semi-random 15 digit number.
  # The length of the ID matters because a float with more than 15 digits is represented using scientific notation.
  # Keep the id length less than 16 digits to avoid this issue.
  def self.random_uuid
    # 11 digit timestamp for uniqueness
    timestamp = Time.now.strftime("%m%d%H%M%S")
    # Max 4 digit random number
    random_number = SecureRandom.random_number(9999)
    # 15 digit unique number padded with 0
    "#{timestamp}#{random_number.to_s.rjust(4, '0')}".to_i
  end
end
