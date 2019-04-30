module Queries
  class FamilyDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def person_search search_string
      return Family if search_string.blank?
    end
    def build_scope
      #return Family if @search_string.blank?
      #person_id = Person.search(@search_string).limit(5000).pluck(:_id)
      #family_scope = Family.where('family_members.person_id' => {"$in" => person_id})
      family = Family.all
      person = Person
      @custom_attributes.values.each do |scope_value|
        if scope_value.present? && family.respond_to?(scope_value)
          family = family.send(scope_value)
        end
      end
      return family if @search_string.blank? || @search_string.length < 2
      person_id = Person.search(@search_string, nil, nil, true).pluck(:_id)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family_scope = family.and('family_members.person_id' => {"$in" => person_id})
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
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
      Family
    end

    def size
      build_scope.count
    end

  end
end
