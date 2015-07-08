require "csv"

hios_to_file = {}

CSV.foreach(File.join(File.dirname(__FILE__), "shop_sbc_file_mapping.csv"), :headers => true) do |row|
    hios = row[0]
    name = row[1]
    clean_hios = hios.strip.gsub(/[^0-9A-Za-z]/, "")
    hios_to_file[clean_hios] = name.strip
end

Plan.where("active_year" => 2015).each do |plan|
  hios_key = plan.hios_id.split("-").first
  if hios_to_file.has_key?(hios_key.strip)
    plan.sbc_file = hios_to_file[hios_key.strip]
    plan.save!
  end
end
