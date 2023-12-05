# frozen_string_literal: true

# Usage: bundle exec rails runner script/recreate_db_indexes.rb

# Removes and creates indexes for all models that have a collection and have indexes specified

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
(Dir["#{Rails.root}/app/models/**/*.rb"] + Dir["#{Rails.root}/components/*/app/models/**/*.rb"]).each { |model_path| require model_path }

# All models that include Mongoid::Document, including inherited models
all_mongoid_models = ObjectSpace.each_object(Class).select { |klass| klass < Mongoid::Document }.sort_by(&:name)

def time_elapsed(start_time)
  end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  seconds_elapsed = end_time - start_time
  p "Total time taken for the process to complete: #{
    format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
  }"
end

all_mongoid_models.each do |model|
  p "Checking if #{model.name} is an eligible model to process"
  if model.embedded? || model.index_specifications.empty?
    p "----- Ineligible model #{model.name}, skipping. -----"
    next
  else
    p "----- Eligible model #{model.name}, processing. -----"
  end

  model.remove_indexes
  model.create_indexes
  p "----- Removed and Created indexes for #{model.name} -----"
rescue Mongo::Error::OperationFailure => e
  p "***** Error raised processing #{model.name}, message: #{e} *****"
end

time_elapsed(start_time)
