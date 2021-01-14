PERSON_HBX_ID_RECORDS = [
  "155960",
  "158174",
  "172802",
  "19746261",
  "19759480",
  "19758517",
  "19762104",
  "19787368",
  "19850646",
  "19853183",
  "19879554",
  "19910173",
  "19920917",
  "19932643",
  "19947218",
  "19956298",
  "19964251",
  "19970472",
  "19995654",
  "20003287",
  "20008040",
  "20017200",
  "20029063",
  "20043824",
  "20048021",
  "20051560",
  "20052592",
  "20055061",
  "20076265",
  "20102727",
  "19765440"
]

def find_primary_family(client, person_id)
  primary_id = find_person_id(person_id)
  family = Family.where(
    {
      "family_members" => {
        "$elemMatch" => {
          "family_member_id" => primary_id,
          "is_primary_applicant" => true
        }
      }
    }
  ).first

  primary = find_person_document(client, primary_id).as_extended_json
  primary_history = find_history_tracks(client, primary_id)

  member_jsons = family.family_members.reject do |fm|
    fm.is_primary_applicant
  end.map do |fm|
    person = find_person_document(client, fm.person_id)
    history_tracks = find_history_tracks(client, fm.person_id)
    {
      person: (person.as_extended_json.reject { |k,v| k.to_s == "inbox" }),
      history_tracks: history_tracks.map(&:as_extended_json)
    }
  end

  {
    family_id: family.id,
    primary: {
      person: (primary.as_extended_json.reject { |k,v| k.to_s == "inbox" }),
      history_tracks: primary_history.map(&:as_extended_json)
    },
    members: member_jsons
  }
end

def find_history_tracks(client, person_id)
  lookup_id = BSON::ObjectId.from_string(person_id)
  collection = client[:history_tracks]
  results = Array.new
  Person.find(
    lookup_id
  ).first.history_tracks.each do |doc|
    results << doc
  end
  results
end

def find_person_id(hbx_id)
  Person.where("hbx_id" => hbx_id).first.id
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
PERSON_HBX_ID_RECORDS.each do |id|
  family = find_primary_family(client, id)

  File.open("#{id}.json", 'wb') do |f|
    f.puts(
      family.to_json
    )
  end
end