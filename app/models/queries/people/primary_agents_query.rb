module Queries
  module People
    class PrimaryAgentsQuery
      include Enumerable

      def each
        id_set.each_slice(500) do |id_list|
          Person.where("_id" => {"$in" => id_list}).each do |pers|
            yield pers
          end
        end
      end

      def each_with_index
        i = 0
        id_set.each_slice(500) do |id_list|
          Person.where("_id" => {"$in" => id_list}).each do |pers|
            yield pers, i
            i = i + 1
          end
        end
      end

      protected

      # We'll start our optimization here in a very lazy way, we're going to
      # disjoin the query and then just use the IDs to iterate directly
      # We can re-combine once we have a better understanding of the index
      # issues and speed problems
      def id_set
        (broker_role_query + ga_staff_query).uniq
      end

      def broker_role_query
        Person.where({
          "is_active" => true,
          "broker_role._id" => {"$exists" => true}
        }).pluck(:_id)
      end

      def ga_staff_query
        Person.where({
          "is_active" => true,
          "general_agency_staff_roles.is_primary" =>  true
        }).pluck(:_id)
      end
    end
  end
end