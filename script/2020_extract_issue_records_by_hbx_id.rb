PERSON_ID_RECORDS = [
  "20001364",
  "19964429",
  "19789096",
  "18770999",
  "10000119",
  "100000008",
  "20033676",
  "20034151",
  "20054135"
]

def find_person_document(client, hbx_id)
  collection = client[:people]
  results = Array.new
  collection.find(hbx_id: hbx_id).each do |doc|
    results << doc
  end
  results.first
end

db_client = Person.collection.client
PERSON_ID_RECORDS.each do |id|
  person_json_hash = find_person_document(db_client, id).as_extended_json

  File.open("#{id}.json", 'wb') do |f|
    f.puts(
      person_json_hash.to_json
    )
  end
end