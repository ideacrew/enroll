# This merely checks index *COUNTS* it does not check if index content is correct

no_collection_list = []
mismatched_list = []
correction_list = []

Mongoid.models.each do |model|
  next if model.index_specifications.empty?
  if !model.embedded? || model.cyclic?
    begin
      actual_indexes = model.collection.indexes.count - 1
      specified_indexes = model.index_specifications.count

      if actual_indexes != specified_indexes
        mismatched_list << "#{model.name}: #{actual_indexes}/#{specified_indexes}"
        correction_list << model.name
      end
    rescue Mongo::Error::OperationFailure
      no_collection_list << "- #{model.name}"
    end
  end
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