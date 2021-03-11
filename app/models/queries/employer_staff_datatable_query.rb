# frozen_string_literal: true

module Queries
  # This class queries all the person records with employer staff role for employer staff datatable
  class EmployerStaffDatatableQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def build_scope
      people = Person.all_employer_staff_roles.where(:'employer_staff_roles.aasm_state' => 'is_active')
      return people if @search_string.blank? || @search_string.length < 2
      person_scope = build_people_id_criteria(@search_string)
      return person_scope if @order_by.blank?
      person_scope.order_by(@order_by)
    end

    def build_people_id_criteria(s_string)
      clean_str = s_string.strip
      people = Person.all_employer_staff_roles.where(:'employer_staff_roles.aasm_state' => 'is_active')
      if clean_str =~ /[a-z]/i
        people_ids = people.collection.aggregate([
                      {"$match" => {
                        "$text" => {"$search" => clean_str}
                      }.merge(Person.search_hash(clean_str))},
                      {"$project" => {"first_name" => 1, "last_name" => 1, "full_name" => 1}},
                      {"$sort" => {"last_name" => 1, "first_name" => 1}},
                      {"$project" => {"_id" => 1}}
                    ], {allowDiskUse: true}).map do |rec|
                      rec["_id"]
                    end
        Person.where(:id => {"$in" => people_ids})
      else
        people.search(s_string, nil, nil, true).pluck(:_id)
      end
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      Person
    end

    def size
      build_scope.count
    end
  end
end
