# frozen_string_literal: true

MoneyRails.configure do |config|
  # set global defaults to avoid warnings in logs
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_EVEN
end
