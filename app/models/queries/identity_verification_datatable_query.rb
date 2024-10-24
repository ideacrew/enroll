module Queries
  class IdentityVerificationDatatableQuery

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

    def build_scope()
      family = EnrollRegistry.feature_enabled?(:show_people_with_no_evidence) ? Person.for_admin_approval : Person.for_admin_approval_with_documents
      person = Person
      #add other scopes here
      family = family.order_by(@order_by) if @order_by.present?
      return family if @search_string.blank? || @search_string.length < 2
      person_id = Person.search(@search_string).pluck(:_id)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family.and('_id' => {"$in" => person_id})
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
