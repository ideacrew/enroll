module System

  path = Rails.root.join(Registry.config.system_dir, "config")

  Dir.glob(File.join(path, "*")).each do |file_path|
    ResourceRegistry::Services::LoadRegistryOptions.new.call(file_path)
  end

  Registry.finalize!(freeze: true) #if defined? Rails && Rail.env == 'production'
end