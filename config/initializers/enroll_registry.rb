# frozen_string_literal: true

require Rails.root.join('app', 'domain', 'types.rb')

EnrollRegistry = ResourceRegistry::Registry.new

# Encapsulates setting the policy used for access
module EnrollRegistryPolicySettings
  def policy_class
    EnrollRegistryPolicy
  end
end

# Syntax compatible methods for github CodeQL.  It currently can't parse code of the form:
# ::EnrollRegistry[:aca_fehb_dependent_age_off] { { new_date: dao_date, enrollment: enrollment } }
module EnrollSyntaxCompatibleRegistryMethods
  def lookup(key, &blk)
    self.[](key, &blk)
  end
end

EnrollRegistry.extend(EnrollRegistryPolicySettings)
EnrollRegistry.extend(EnrollSyntaxCompatibleRegistryMethods)

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('system', 'config', 'templates', 'features').to_s
end
