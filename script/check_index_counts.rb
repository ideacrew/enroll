# frozen_string_literal: true

# Usage: bundle exec rails runner script/check_index_counts.rb

# This merely checks index *COUNTS* it does not check if index content is correct

# Checks if the number of indexes specified in the model matches the number of indexes in the database for each model which is eligible to have indexes.
# Prints outputs as: (Model): (actually exists)/(should exist)
# Generates a correction script to fix the discrepancies

no_collection_list = []
mismatched_list = []
correction_list = []

(Dir["#{Rails.root}/app/models/**/*.rb"] + Dir["#{Rails.root}/components/*/app/models/**/*.rb"]).each { |model_path| require model_path }

# All models that include Mongoid::Document, including inherited models
all_mongoid_models = ObjectSpace.each_object(Class).select { |klass| klass < Mongoid::Document }.sort_by(&:name)

all_mongoid_models.each do |model|
  next if model.embedded? || model.index_specifications.empty?

  actual_indexes = model.collection.indexes.count - 1
  specified_indexes = model.index_specifications.count

  if actual_indexes != specified_indexes
    mismatched_list << "#{model.name}: #{actual_indexes}/#{specified_indexes}"
    correction_list << model.name
  end
rescue Mongo::Error::OperationFailure
  no_collection_list << "- #{model.name}"
end

correction_script = <<-RUBYCODE
# A correction script to fix mongob index discrepencies

RUBYCODE

correction_list.each do |cli|
  new_script = <<-RUBYCODE
# Update indexes for #{cli}
#{cli}.remove_indexes
#{cli}.create_indexes

RUBYCODE

  correction_script = correction_script + new_script
end

puts "\n\nPrints outputs as: (Model): (actually exists)/(should exist)"

mismatched_list.each { |mmi| puts mmi }

puts "\n\nThe following models have no collections, and are ignored:"

no_collection_list.each { |nci| puts nci }

puts "\n\nGenerating Correction Script:"
puts "------------- SNIP HERE -------------"
puts correction_script