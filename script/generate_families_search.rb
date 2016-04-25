class FamilySearchRunOnce
    include ::MapReduce::FamilySearchCommon

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
      people_hash = people_hash_for(@person_ids)
      @map_reduce.scope({
        people: people_hash_for(@person_ids)
      })
      @map_reduce.counts
    end
end

bail_count = 0

loop do
  family_ids = []
  people_ids = []

  family_search_ids = FamilySearch.where({}).pluck("_id")
  puts Family.collection.aggregate([
    {"$match" => {"_id" => {"$nin" => family_search_ids}}},
    {"$unwind" => "$family_members"},
    {"$group" => {"_id" => "$_id", "family_member_ids" => {"$addToSet" => "$family_members.person_id"}}}
  ]).count
  Family.collection.aggregate([
    {"$match" => {"_id" => {"$nin" => family_search_ids}}},
    {"$unwind" => "$family_members"},
    {"$group" => {"_id" => "$_id", "family_member_ids" => {"$addToSet" => "$family_members.person_id"}}},
    {"$limit" => 1000}
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
