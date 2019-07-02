require 'dry-validation'
require 'date'
require 'mail'

module BenefitSponsors
  class BaseSchemaValidator < Dry::Validation::Schema
    configure  do |config|
      config.messages = :i18n
    end
  end
end