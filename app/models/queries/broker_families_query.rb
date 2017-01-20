module Queries
  class BrokerFamiliesQuery

    def initialize(s_string, broker_agency_id)
      @use_search = !s_string.blank?
      @search_string = s_string
      @broker_agency_profile_id = broker_agency_id
    end

    def build_base_scope
      Family.by_broker_agency_profile_id(@broker_agency_profile_id)
    end

    def build_filtered_scope
      return build_base_scope unless @use_search
      person_id = Person.where(Person.search_hash(@search_string)).limit(100).pluck(:_id)
      build_base_scope.where('family_members.person_id' => {"$in" => person_id})
    end

    def filtered_scope
      @filtered_scope ||= build_filtered_scope
    end

    def base_scope
      @base_scope ||= build_base_scope
    end

    def total_count
      base_scope.count
    end

    def filtered_count
      filtered_scope.count
    end

  end
end
