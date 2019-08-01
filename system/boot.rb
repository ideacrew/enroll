module System

  path = Rails.root.join(Registry.config.system_dir, "config")
  ResourceRegistry.load_options!(path)
  
  Registry.finalize!(freeze: true) #if defined? Rails && Rail.env == 'production'
end