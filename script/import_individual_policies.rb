data_string = File.read("glue_individual_policies.json")
data_hash = JSON.load(data_string)
data_hash.each do |data|
  importer = LegacyImporters::IndividualPolicy.new(data)
  if !importer.save
    puts importer.errors.full_messages.join("\n")
  end
end
