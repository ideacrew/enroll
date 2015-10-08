data_string = File.read("glue_shop_policies.json")
data_hash = JSON.load(data_string)
data_hash.each do |data|
  importer = LegacyImporters::ShopPolicy.new(data)
  if !importer.save
    puts importer.errors.full_messages.join("\n")
  end
end
