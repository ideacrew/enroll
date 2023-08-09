
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
    # Timestamp is 10 digits. Random number is 5 digits.
    "#{Time.now.to_i}#{rand(10_000...99_999)}".to_i
  end
end
