EnrollRegistry = ResourceRegistry::Registry.new

# Syntax compatible methods for github CodeQL.  It currently can't parse code of the form:
# ::EnrollRegistry[:aca_fehb_dependent_age_off] { { new_date: dao_date, enrollment: enrollment } }
module EnrollSyntaxCompatibleRegistryMethods
  def lookup(key, &blk)
    self.[](key, &blk)
  end
end

EnrollRegistry.extend(EnrollSyntaxCompatibleRegistryMethods)

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = Rails.root.to_s.gsub("/components/benefit_sponsors/spec/dummy", "") + "/system/config/templates/features"
end
