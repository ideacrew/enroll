PERSON_HBX_ID_RECORDS = [
  "169646",
  "172802",
  "190420",
  "2703803",
  "19749873",
  "19841135",
  "19841140",
  "19851979",
  "19920917",
  "19964251",
  "20048342",
  "20049335",
  "20052481",
  "20084583",
  "20084586",
  "20092423",
  "20092424",
  "20093478",
  "20121578"
]

def find_families(client, person_id)
  primary_ids = find_person_ids(person_id)


  primary_ids.each do |primary_id|
    family = Family.where(
      {
        "family_members" => {
          "$elemMatch" => {
            "person_id" => primary_id,
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

    family_json = {
      family_id: family.id,
      primary: {
        person: (primary.as_extended_json.reject { |k,v| k.to_s == "inbox" }),
        history_tracks: primary_history.map(&:as_extended_json)
      },
      members: member_jsons
    }

    File.open("#{person_id}_#{primary_id}_primary.json", 'wb') do |f|
      f.puts(
        family_json.to_json
      )
    end

    other_families = Family.where(
      {
        "family_members" => {
          "$elemMatch" => {
            "person_id" => primary_id
          }
        }
      }
    )

    other_families.each do |o_fam|
      next if o_fam.id == family.id
      other_member_jsons = o_fam.family_members.reject do |fm|
        fm.is_primary_applicant
      end.map do |fm|
        person = find_person_document(client, fm.person_id)
        history_tracks = find_history_tracks(client, fm.person_id)
        {
          person: (person.as_extended_json.reject { |k,v| k.to_s == "inbox" }),
          history_tracks: history_tracks.map(&:as_extended_json)
        }
      end

      other_primary = o_fam.family_members.detect do |fm|
        fm.is_primary_applicant
      end

      other_primary_id = other_primary.person_id

      other_primary = find_person_document(client, other_primary_id).as_extended_json
      other_primary_history = find_history_tracks(client, other_primary_id)

      other_family_json = {
        family_id: o_fam.id,
        primary: {
          person: (other_primary.as_extended_json.reject { |k,v| k.to_s == "inbox" }),
          history_tracks: other_primary_history.map(&:as_extended_json)
        },
        members: other_member_jsons
      }

      File.open("#{person_id}_#{primary_id}_#{o_fam.id}.json", 'wb') do |f|
        f.puts(
          other_family_json.to_json
        )
      end
    end
  end
end

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

def find_person_ids(hbx_id)
  Person.where("hbx_id" => hbx_id).map do |person|
    person.id
  end
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
  family = find_families(db_client, id)
end