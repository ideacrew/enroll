module System
  # require_relative "local/inject"

  require ResourceRegistry.services_path.join('load_registry').to_s

  path = Rails.root.join(Registry.config.system_dir, Registry["persistence.container"])
  ResourceRegistry::Services::LoadRegistry.call(path: path)
  Registry.finalize!(freeze: true) # if defined? Rails && Rail.env == 'production'

  # Repository.namespace(:options) do |container|
  #   path  = container.config.root.join(container.config.system_dir, 'config')
  #   obj   = LoadOptions.load_attr(path)
  #   obj.to_hash.each_pair { |key, value| container.register("#{key}".to_sym, "#{value}") }
  # end

  # # EnrollContainer.finalize!(freeze: true) # if defined? Rails && Rail.env == 'production'
  # # set constant
end