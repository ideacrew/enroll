Before do
  Rails.cache.clear
  DatabaseCleaner.strategy = DatabaseCleaner::Mongoid::Deletion.new(except: %w[translations])
  DatabaseCleaner.clean
  TimeKeeper.set_date_of_record_unprotected!(Date.today)
end
