module Notifier
  class Engine < ::Rails::Engine
    isolate_namespace Notifier

    config.generators do |g|
      g.orm :mongoid 
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets true
      g.helper true 
    end
  end
end
