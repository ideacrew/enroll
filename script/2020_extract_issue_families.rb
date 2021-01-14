PERSON_HBX_ID_RECORDS = [
  "155960",
  "158174",
  "169646",
  "172802",
  "183003",
  "18769379",
  "190420",
  "2703803",
  "19746108",
  "19746261",
  "19749493",
  "19749873",
  "19753984",
  "19759480",
  "19758517",
  "19762104",
  "19764728",
  "19766042",
  "19776309",
  "19777801",
  "19778040",
  "19778459",
  "19787368",
  "19805749",
  "19811916",
  "19823225",
  "19825260",
  "19833118",
  "19847758",
  "19850091",
  "19850646",
  "19851979",
  "19853183",
  "19873052",
  "19879554",
  "19903306",
  "19910173",
  "19915022",
  "19920122",
  "19920917",
  "19921112",
  "19925324",
  "19932643",
  "19936288",
  "19940353",
  "19947218",
  "19956298",
  "156512",
  "19963330",
  "19964251",
  "19966380",
  "19970472",
  "19971857",
  "19879671",
  "19974685",
  "19995654",
  "19886718",
  "20003287",
  "20004008",
  "20008040",
  "20008814",
  "20014683",
  "20017200",
  "20025928",
  "20029063",
  "19987034",
  "20043824",
  "20044389",
  "20031274",
  "20048021",
  "20049335",
  "20048342",
  "20051560",
  "20052481",
  "20052592",
  "20053497",
  "20054401",
  "20055061",
  "20062827",
  "20073019",
  "20076265",
  "20094903",
  "20096180",
  "20102727",
  "19765440",
  "20121140"
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
  family = find_primary_family(db_client, id)

  File.open("#{id}.json", 'wb') do |f|
    f.puts(
      family.to_json
    )
  end
end