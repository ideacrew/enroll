require 'dry-validation'
require 'date'
require 'mail'

module BenefitSponsors
  class BaseParamValidator < Dry::Validation::Schema::Params
    configure  do |config|
      config.messages = :i18n
    end

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
end