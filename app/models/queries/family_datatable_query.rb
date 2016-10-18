module Queries
  class FamilyDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      puts "initializing #{attributes}"
      @custom_attributes = attributes
    end

    def person_search search_string
      return Family if search_string.blank?


    end

    def build_scope()
      puts "#{@custom_attributes} are attributes,#{@custom_attributes['aptc']} "
      family = Family
      if @custom_attributes['individual_options'] == 'all_assistance_receiving'
        family = family.all_assistance_receiving
      end
      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 3
      person_id = Person.search(@search_string).pluck(:_id)
      family_scope = family.where('family_members.person_id' => {"$in" => person_id})
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
