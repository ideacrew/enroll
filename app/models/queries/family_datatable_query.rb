module Queries
  class FamilyDatatableQuery

    attr_reader :search_string

    def datatable_search(string)
      @search_string = string
      self
    end

    def count
      #return Family.count if @search_string.blank?
      build_scope.count
    end

    def build_scope()
      return Family if @search_string.blank?
      person_id = Person.search(@search_string).pluck(:_id)
      family_scope = Family.where('family_members.person_id' => {"$in" => person_id})
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end
    
    def skip(num)
      build_scope.skip(num)
    end

    def take(num)
      build_scope.take(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      Family
    end

    def size
      Family.count
    end

  end
end
