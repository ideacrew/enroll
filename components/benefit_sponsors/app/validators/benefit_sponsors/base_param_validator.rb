require 'i18n'
require 'dry-schema'
require 'date'
require 'mail'

module BenefitSponsors
  class BaseParamValidator < Dry::Schema::Params
    define do
      config.messages.backend = :i18n
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