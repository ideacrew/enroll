module ViewFunctions
  class Family
    def after_save_search_update
      # Name: familySavedSearchUpdate
      <<-MONGOJS
function(familyDoc) {
    var peopleIds = [];
    var primaryId = null;
    var primaryPerson = null;
    var familyPeople = [];
    familyDoc.family_members.forEach(function(fm) {
       if (fm.is_active) {
         if (fm.is_primary_applicant) {
             primaryId = fm.person_id;
         }
         peopleIds.push(fm.person_id);
       }
    });
    db.people.find({_id: {$in: peopleIds}}).forEach(function(per) {
        if (per._id.equals(primaryId)) {
          primaryPerson = {
            person_id: per._id,
            first_name: per.first_name,
            last_name: per.last_name
          };
          if (!((per.middle_name == null) || (per.middle_name == undefined))) {
              primaryPerson['middle_name'] = per.middle_name
          }
          if (!((per.name_pfx == null) || (per.name_pfx == undefined))) {
              primaryPerson['name_pfx'] = per.name_pfx
          }
          if (!((per.name_sfx == null) || (per.name_sfx == undefined))) {
              primaryPerson['name_sfx'] = per.name_sfx
          }
        } else {
            var personRecord = {
            person_id: per._id,
            first_name: per.first_name,
            last_name: per.last_name
            };
          if (!((per.middle_name == null) || (per.middle_name == undefined))) {
              personRecord['middle_name'] = per.middle_name
          }
          if (!((per.name_pfx == null) || (per.name_pfx == undefined))) {
              personRecord['name_pfx'] = per.name_pfx
          }
          if (!((per.name_sfx == null) || (per.name_sfx == undefined))) {
              personRecord['name_sfx'] = per.name_sfx
          }
            familyPeople.push(personRecord);
        }
    });
    db.family_search.update(
    {_id: familyDoc._id},
    {
      _id: familyDoc._id,
      primary_person: primaryPerson,
      family_people: familyPeople
    },
    {upsert: true});
}
      MONGOJS
  end
end
