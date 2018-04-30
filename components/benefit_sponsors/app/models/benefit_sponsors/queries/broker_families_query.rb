module BenefitSponsors
  module Queries
    class BrokerFamiliesQuery

      def initialize(s_string, broker_agency_id)
        @use_search = !s_string.blank?
        @search_string = s_string
        @broker_agency_profile_id = broker_agency_id
      end

      def build_base_scope
        ivl_broker_agency_criteria = { broker_agency_accounts: {:$elemMatch=> {broker_agency_profile_id: @broker_agency_profile_id, is_active: true}} }
        shop_broker_agency_criteria = { "family_members.person_id" => {"$in" => employee_person_ids }}
        { "$or" => [
          ivl_broker_agency_criteria,
          shop_broker_agency_criteria
        ]}
      end

      def build_filtered_scope
        return build_base_scope unless @use_search
        person_id = Person.where(Person.search_hash(@search_string)).limit(700).pluck(:_id)
        {
          "$and" => [
            { 'family_members.person_id' => {"$in" => person_id} },
            build_base_scope
          ]
        }
      end

      def filtered_scope
        @filtered_scope ||= Family.where(build_filtered_scope)
      end

      def base_scope
        @base_scope ||= Family.where(build_base_scope)
      end

      def total_count
        base_scope.count
      end

      def filtered_count
        filtered_scope.count
      end

      def employee_person_ids
        # TODO:  Revisit when CensusEmployee an BenefitSponsorship relationships are completed.
        benefit_sponsorships_ids ||= BenefitSponsors::Organizations::Organization.employer_profiles.collection.aggregate([
          { "$match" => { :'benefit_sponsorships.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: @broker_agency_profile_id } } } },
          { "$group" => { "_id" => "$benefit_sponsorships._id" }}
        ]).map { |rec| rec["_id"] }

        census_employee_ids = benefit_sponsorships_ids.inject([]) do |arr, benefit_sponsorships_id|
          arr + BenefitSponsors::CensusMembers::CensusEmployee.find_by_benefit_sponsorship(benefit_sponsorships_id).id
        end

        employee_person_ids ||= Person.unscoped.where("employee_roles.census_employee_id" => {"$in" => census_employee_ids}).pluck(:_id)
      end
    end
  end
end