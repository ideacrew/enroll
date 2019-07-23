require 'i18n'
require 'dry-schema'
require 'date'
require 'mail'

module BenefitSponsors
  module ValidationTypes
    include Dry::Types()
  end

  BsonObjectIdString = ValidationTypes.Constructor(BSON::ObjectId) do |value|
    begin
      BSON::ObjectId.from_string(value)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  class BaseParamValidator < Dry::Schema::Params
    define do
      config.messages.backend = :i18n
      config.messages.load_paths += Dir[
        Rails.root.join('config', 'locales', 'dry_validation.*.yml')
      ]
    end
  end

  module CommonPredicates
    def us_date?(value)
      (Date.strptime(value, "%m/%d/%Y") rescue nil).present?
    end

    def email?(value)
      begin
        parsed = Mail::Address.new(value)
        true
      rescue Mail::Field::ParseError => e
        false
      end
    end
  end

  Dry::Logic::Predicates.extend(CommonPredicates)
end