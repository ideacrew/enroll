#frozen_string_literal: true

require 'monetize'

module Monetize
  def self.from_numeric(value, currency = Money.default_currency)
    case value
    when Integer
      from_fixnum(value, currency)
    when Numeric
      value = BigDecimal(value.to_s)
      from_bigdecimal(value, currency)
    else
      raise ArgumentError, "'value' should be a type of Numeric"
    end
  end
end