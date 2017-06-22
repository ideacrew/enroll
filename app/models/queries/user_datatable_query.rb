module Queries
  class UserDatatableQuery
  	attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def build_scope()
      user = User
      case @custom_attributes[:users]
        when "all_employer_staff_roles"
          user.where(:'roles'.in => ["employer_staff"])
        when "all_employee_roles"
          user.where(:'roles'.in => ["employee"])
        when "all_broker_roles"
          user.where(:'roles'.in => ["broker"])
        when "locked"
          user.locked
        when "unlocked"
          user.unlocked
        else
          user.all
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
      Family
    end

    def size
      build_scope.count
    end
  end
end