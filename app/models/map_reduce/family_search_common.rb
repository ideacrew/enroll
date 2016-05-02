module MapReduce
  module FamilySearchCommon
    def map_function
      <<-JS_CODE
      function() {
         var fam = this;
         for (var i = 0; i < this["family_members"].length; i++) {
           var family_member = this["family_members"][i];
           fam["family_members"][i]["person"] = people[family_member["person_id"].valueOf()];
         }
         delete(fam['versions']);
         emit(fam._id, fam);
      }
      JS_CODE
    end

    def reduce_function
      <<-JS_CODE
      function(key, values) {
        return values;
      }
      JS_CODE
    end

    def people_hash_for(person_ids)
      person_data = {}
      Person.where({"_id" => {"$in" => person_ids}}).each do |pers|
        person_data[pers._id.to_s] = pers.as_json(:except => [:inbox, :versions])
      end
      person_data
    end

    def reduced_collection
      Family.collection
    end
  end
end
