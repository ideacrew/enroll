PERSON_ID_RECORDS = [
  "5d08fd82cc35a8797f00008b",
  "5beb73ade59c4a213f000000",
  "5bedcd13cabc326ef100017c",
  "5c77095de59c4a23e6000000"
]

def find_history_tracks(client, person_id)
  lookup_id = BSON::ObjectId.from_string(person_id)
  collection = client[:history_tracks]
  results = Array.new
  Person.find(
    lookup_id
  ).history_tracks.each do |doc|
    results << doc
  end
  results
end

def find_person_document(client, person_id)
  lookup_id = BSON::ObjectId.from_string(person_id)
  collection = client[:people]
  results = Array.new
  collection.find(_id: lookup_id).each do |doc|
    results << doc
  end
  results.first
end

db_client = Person.collection.client
PERSON_ID_RECORDS.each do |id|
  person_json_hash = find_person_document(db_client, id).as_extended_json
  history_hash = find_history_tracks(db_client, id).map(&:as_extended_json)

  File.open("#{id}.json", 'wb') do |f|
    f.puts(
      {
        person: person_json_hash,
        history: history_hash
      }.to_json
    )
  end
end