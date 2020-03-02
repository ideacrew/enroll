module Queries
  module People
    class PrimaryAgentsQuery
      include Enumerable

      def each
        person_query.each do |pers|
          if pers.is_active
            yield pers
          end
        end
      end

      def each_with_index
        i = 0
        person_query.each do |pers|
          if pers.is_active
            yield pers, i
            i = i + 1
          end
        end
      end

      protected

      def person_query
        Person.where({
          "$or" => [
            {"broker_role._id" => {"$ne" => nil}},
            {"general_agency_staff_roles.is_primary" => true}]
        })
      end
    end
  end
end