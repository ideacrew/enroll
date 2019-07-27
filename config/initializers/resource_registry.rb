# ResourceRegistry.configure do |config|
#   config.store      = 'file_store'
#   config.container  = 'db/seedfiles/registry/'
#   config.serializer = 'yaml_serializer'
# end

# ResourceRegistry.configure do
#   {
#     registry_name: 'Registry',
#     app_name: 'enroll',
#     persistence: {
#       store: 'file_store',
#       serializer: 'yaml_serializer',
#       container: "db/seedfiles/registry/"
#     },
#     registry_container: {
#       auto_register: []
#     },
#     options: {
#       # place to add additional/override key value pairs
#       # this will use the same feature that supports dynamic updates like tenants
#     }
#   }
# end

ResourceRegistry.configure do 
  {
    config: {
      name: "public",
      default_namespace: "core",
      root: nil,
      # relative_root: nil
      system_dir: "system",
      auto_register: []
    },
    load_paths: ['system'],
    persistence:{
      store: "file_store",
      serializer: "yaml_serializer",
      container: "config"
    },
    options: {
    }
  }
end

Kernel.const_set("Registry", ResourceRegistry::PublicRegistry)
ResourceRegistry.const_set(:RegistryInjector, Registry.injector)
require_relative Rails.root.join('system', 'boot')
  