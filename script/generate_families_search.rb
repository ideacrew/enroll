class FamilySearchRunOnce
    def initialize(family_ids, person_ids)
      @family_ids = family_ids
      @person_ids = person_ids
      @map_reduce = Mongoid::Contextual::MapReduce.new(
        Family.collection,
        Family.where({"_id" => {"$in" => @family_ids}}),
        map_function,
        reduce_function
      ) 
     @map_reduce.out({merge: "families_search"})
    end

    def execute
      @map_reduce.scope({
        people: people_hash_for(@person_ids)
      })
      @map_reduce.count
    end

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
end


loop do
  family_ids = []
  people_ids = []

  family_search_ids = FamilySearch.where({}).pluck("_id")
  Family.collection.aggregate([
    {"$match" => {"_id" => {"$nin" => family_search_ids}}},
    {"$unwind" => "$family_members"},
    {"$group" => {"_id" => "$_id", "family_member_ids" => {"$addToSet" => "$family_members.person_id"}}},
    {"$limit" => 100}
  ]).each do |rec|
    family_ids << rec['_id']
    rec["family_member_ids"].each do |fmi|
      people_ids << fmi
    end
    people_ids.uniq!
  end
  break if family_ids.empty?
  FamilySearchRunOnce.new(family_ids, people_ids).execute
end

