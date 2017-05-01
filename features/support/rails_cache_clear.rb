Before do
  Rails.cache.clear
  DatabaseCleaner.strategy = :truncation, {:except => %w[rate_reference]}
end