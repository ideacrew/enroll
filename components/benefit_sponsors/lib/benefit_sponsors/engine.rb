# require 'active_model_serializers'
require 'slim'
require 'effective_datatables'
require 'virtus'
require 'devise'
require 'pundit'
require 'language_list'
require 'interactor'

module BenefitSponsors
  class Engine < ::Rails::Engine
    isolate_namespace BenefitSponsors

    initializer "benefit_sponsors.factories", :after => "Factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :Factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper true
    end

    config.to_prepare do
#      BenefitSponsors::ApplicationController.helper Rails.application.helpers
    end

    initializer "webpacker.proxy" do |app|
      insert_middleware =
        begin
          BenefitSponsors.webpacker.config.dev_server.present?
        rescue StandardError => e
          e.message
        end
      next unless insert_middleware

      app.middleware.insert_before(
        0, Webpacker::DevServerProxy, # "Webpacker::DevServerProxy" if Rails version < 5
        ssl_verify_none: true,
        webpacker: BenefitSponsors.webpacker
      )
    end
  end
end
