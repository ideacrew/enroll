# frozen_string_literal: true

require Rails.root.join('app', 'domain', 'types.rb')

EnrollRegistry = ResourceRegistry::Registry.new

# Encapsulates setting the policy used for access
module EnrollRegistryPolicySettings
  def policy_class
    EnrollRegistryPolicy
  end
end

EnrollRegistry.extend(EnrollRegistryPolicySettings)

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('system', 'config', 'templates', 'features').to_s
end
