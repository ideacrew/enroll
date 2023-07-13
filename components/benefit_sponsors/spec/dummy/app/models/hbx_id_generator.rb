class HbxIdGenerator
  include Singleton

  def self.generate_policy_id
    uniq_id
  end

  def self.generate_member_id
    uniq_id
  end

  def self.generate_organization_id
    uniq_id
  end

  def self.uniq_id
    Time.now.to_i
  end
end
