require 'virtus'

module SponsoredBenefits
  class Engine < ::Rails::Engine
    isolate_namespace SponsoredBenefits
    
    initializer "sponsored_benefits.factories", :after => "factory_girl.set_factory_paths" do
      FactoryGirl.definition_file_paths << File.expand_path('../../../../../spec/factories', __FILE__) if defined?(FactoryGirl)
      FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
    end
    
    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
