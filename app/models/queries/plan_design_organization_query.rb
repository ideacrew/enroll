module Queries
  class PlanDesignOrganizationQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      puts "****"
      puts @plan_design_organization
      puts string
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(@custom_attributes[:profile_id])
    end

    def build_scope()
      puts "----"
      return [] if @plan_design_organization.nil?
      case @custom_attributes[:clients]
      when "active_clients"
        @plan_design_organization.active_clients
      when "inactive_clients"
        @plan_design_organization.inactive_clients
      when "prospect_employers"
        @plan_design_organization.prospect_employers
      else
        @plan_design_organization
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

    def any?
      build_scope.each do |e|
        return if yield(e)
      end
    end

    def klass
      Family
    end

    def size
      build_scope.count
    end
  end
end
